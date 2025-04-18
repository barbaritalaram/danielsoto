#include <WiFi.h>
#include <HTTPClient.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include "HX711.h"

// ========== CONFIGURACIÓN WIFI ==========
const char* ssid = "01001110 01101111";
const char* password = "Paleta9835*";

// ========== CONFIGURACIÓN FIREBASE ==========
const char* firebaseHost = "prueba-b-36681-default-rtdb.firebaseio.com";
const char* firebaseAuth = "AIzaSyAClNXhegiF0fQscFNmVTAFoy9I8GhhRXo";  
const String firebasePath = "/colmenas/colmena1.json";

// ========== CONFIGURACIÓN HX711 (BALANZA) ==========
const int LOADCELL_DOUT_PIN = 21;
const int LOADCELL_SCK_PIN = 22;
HX711 balanza;

// ========== CONFIGURACIÓN NTP (FECHA/HORA) ==========
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", -4 * 3600);  // UTC-4 para Chile

// ========== VARIABLES GLOBALES ==========
float pesoInicial = 0;
float pesoFinal = 0;
float segmento25, segmento50, segmento75;
unsigned long ultimoEnvio = 0;
const long intervaloEnvio = 10000;  // 10 segundos entre envíos
bool ntpDisponible = false;

// ========== DECLARACIONES DE FUNCIONES ==========
void solicitarPesos();
void calcularSegmentos();
void conectarWiFi();
void configurarNTP();
String obtenerFechaHora();
float calcularPorcentaje(float peso);
String determinarColor(float peso);
void enviarDatosFirebase(float peso, String color, float porcentaje);
void mostrarConfiguracion();
void mostrarLectura(float peso, float porcentaje, String color);

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n=== SISTEMA DE MONITOREO APÍCOLA ===");
  
  // Solicitar pesos al usuario
  solicitarPesos();
  
  // Calcular segmentos de colores
  calcularSegmentos();
  mostrarConfiguracion();
  
  // Inicializar hardware
  balanza.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  balanza.set_scale(5.f);  // Ajustar según calibración
  balanza.tare();
  Serial.println("Balanza lista");

  // Conectar a WiFi
  conectarWiFi();
  
  // Configurar hora NTP
  configurarNTP();
}

void loop() {
  timeClient.update();  // Actualizar hora

  if (millis() - ultimoEnvio >= intervaloEnvio) {
    if (balanza.is_ready()) {
      // Paso 1: Leer peso y calcular porcentaje
      float peso = balanza.get_units(10);  // Promedio de 10 lecturas
      float porcentaje = calcularPorcentaje(peso);
      String color = determinarColor(peso);
      
      //Mostrar datos en consola
      mostrarLectura(peso, porcentaje, color);
      
      //Enviar a Firebase
      enviarDatosFirebase(peso, color, porcentaje);
      
      ultimoEnvio = millis();
    }
  }
  
  // Reintentar conexión NTP cada 60 segundos si falló
  static unsigned long ultimoIntentoNTP = 0;
  if (!ntpDisponible && millis() - ultimoIntentoNTP > 60000) {
    configurarNTP();
    ultimoIntentoNTP = millis();
  }
}

// ========== FUNCIÓN PARA SOLICITAR PESOS ==========
void solicitarPesos() {
  Serial.println("\n=== CONFIGURACIÓN DE PESOS ===");
  
  // Solicitar peso inicial (validar > 0)
  while (true) {
    Serial.print("Ingrese peso inicial (kg): ");
    while (!Serial.available()) delay(100);
    pesoInicial = Serial.parseFloat();
    Serial.readStringUntil('\n');
    
    if (pesoInicial > 0) break;
    Serial.println("Error: El peso inicial debe ser mayor que 0");
  }
  
  // Solicitar peso final (validar > pesoInicial)
  while (true) {
    Serial.print("Ingrese peso final (kg): ");
    while (!Serial.available()) delay(100);
    pesoFinal = Serial.parseFloat();
    Serial.readStringUntil('\n');
    
    if (pesoFinal > pesoInicial) break;
    Serial.println("Error: El peso final debe ser mayor al inicial");
  }
}

// ========== FUNCIONES AUXILIARES ==========
void calcularSegmentos() {
  float rango = pesoFinal - pesoInicial;
  segmento25 = pesoInicial + (rango * 0.25);
  segmento50 = pesoInicial + (rango * 0.50);
  segmento75 = pesoInicial + (rango * 0.75);
}

void conectarWiFi() {
  Serial.print("\nConectando a WiFi...");
  WiFi.begin(ssid, password);
  
  int intentos = 0;
  while (WiFi.status() != WL_CONNECTED && intentos < 15) {
    delay(1000);
    Serial.print(".");
    intentos++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi conectado");
    Serial.print("Dirección IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nError: No se pudo conectar al WiFi");
  }
}

void configurarNTP() {
  timeClient.begin();
  
  Serial.println("\nObteniendo hora del servidor NTP...");
  int intentos = 0;
  
  while (intentos < 10) {
    if (timeClient.update()) {
      ntpDisponible = true;
      Serial.println("Hora NTP actualizada correctamente");
      Serial.print("Hora actual: ");
      Serial.println(obtenerFechaHora());
      return;
    }
    delay(1000);
    Serial.print(".");
    intentos++;
  }
  
  Serial.println("\nError: No se pudo obtener la hora NTP");
  Serial.println("El sistema usará hora local aproximada");
}

String obtenerFechaHora() {
  if (ntpDisponible) {
    timeClient.update();
    unsigned long epochTime = timeClient.getEpochTime();
    time_t tiempo = (time_t)epochTime;
    struct tm *ptm = localtime(&tiempo);
    
    char fechaHora[30];
    sprintf(fechaHora, "%04d-%02d-%02d %02d:%02d:%02d",
            ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday,
            timeClient.getHours(), timeClient.getMinutes(), timeClient.getSeconds());
            
    return String(fechaHora);
  } else {
    // Fallback: Hora local basada en millis()
    unsigned long segundos = millis() / 1000;
    int horas = (segundos / 3600) % 24;
    int minutos = (segundos / 60) % 60;
    int seg = segundos % 60;
    
    char fechaHora[30];
    sprintf(fechaHora, "2000-01-01 %02d:%02d:%02d", horas, minutos, seg);
    return String(fechaHora);
  }
}

float calcularPorcentaje(float peso) {
  return ((peso - pesoInicial) / (pesoFinal - pesoInicial)) * 100;
}

String determinarColor(float peso) {
  if (peso < segmento25) return "rojo";
  else if (peso < segmento50) return "naranja";
  else if (peso < segmento75) return "amarillo";
  else return "verde";
}

void mostrarConfiguracion() {
  Serial.println("\nConfiguración aplicada:");
  Serial.printf("• Rango: %.1fkg a %.1fkg\n", pesoInicial, pesoFinal);
  Serial.printf("• Segmentos: 25%%=%.1fkg | 50%%=%.1fkg | 75%%=%.1fkg\n", 
                segmento25, segmento50, segmento75);
  Serial.println("El sistema está listo para monitorear.");
}

void mostrarLectura(float peso, float porcentaje, String color) {
  String fechaHora = obtenerFechaHora();
  Serial.printf("\n[%s] Lectura actual:\n", fechaHora.c_str());
  Serial.printf("• Peso: %.2f kg\n", peso);
  Serial.printf("• Porcentaje: %.1f%%\n", porcentaje);
  Serial.printf("• Nivel: %s\n", color.c_str());
}

void enviarDatosFirebase(float peso, String color, float porcentaje) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Error: No hay conexión WiFi para enviar datos");
    return;
  }

  HTTPClient http;
  String url = "https://" + String(firebaseHost) + firebasePath + "?auth=" + String(firebaseAuth);
  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  String fechaHora = obtenerFechaHora();
  String payload = "{";
  payload += "\"peso\":" + String(peso, 3) + ",";
  payload += "\"fechaHora\":\"" + fechaHora + "\",";
  payload += "\"color\":\"" + color + "\",";
  payload += "\"porcentaje\":" + String(porcentaje, 1) + ",";
  payload += "\"pesoInicial\":" + String(pesoInicial, 1) + ",";
  payload += "\"pesoFinal\":" + String(pesoFinal, 1);
  payload += "}";

  Serial.println("\nEnviando datos a Firebase...");
  Serial.println("Payload: " + payload);

  int httpCode = http.PUT(payload);
  
  if (httpCode > 0) {
    if (httpCode == HTTP_CODE_OK) {
      String response = http.getString();
      Serial.println("Datos actualizados correctamente");
    }
  } else {
    Serial.printf("Error en la conexión: %s\n", http.errorToString(httpCode).c_str());
  }
  
  http.end();
}
