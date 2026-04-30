import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

class RegistroPaso3 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const RegistroPaso3({super.key, required this.onNext, required this.onBack});

  @override
  State<RegistroPaso3> createState() => _RegistroPaso3State();
}

class _RegistroPaso3State extends State<RegistroPaso3> {
  bool _showManualCoords = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.home_outlined, size: 24),
            SizedBox(width: 8),
            Text(
              "Ubicación de la Residencia",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Proporciona los datos básicos de tu vivienda y contactos de emergencia",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 10),
        const InputLabel(label: "Dirección completa", required: true),
        const TextField(
          decoration: InputDecoration(
            hintText: "Ej: Av. Libertador 1234, Depto 5B, Las Condes, Santiago",
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Ubicación en el mapa",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Image.network(
                  "https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Santiago_map.png/800px-Santiago_map.png",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFE8F5E9)),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF00A84E), width: 0.5),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF00A84E)),
                        SizedBox(width: 4),
                        Text("Vista previa de ubicación", style: TextStyle(fontSize: 12, color: Color(0xFF00A84E))),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 40),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: const Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 12, color: Colors.pink),
                                SizedBox(width: 4),
                                Text("Ubicación en Santiago", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Text("Ingresa tu dirección para una ubicación más precisa", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    child: const Row(
                      children: [
                        Icon(Icons.home, size: 14, color: Colors.brown),
                        SizedBox(width: 4),
                        Text("Residencia", style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    child: const Row(
                      children: [
                        Icon(Icons.location_searching, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text("Coordenadas: -33.4°, -70.6°", style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 100,
                  child: Column(
                    children: [
                      _buildMapButton(Icons.add),
                      const SizedBox(height: 4),
                      _buildMapButton(Icons.remove),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Esta vista previa ayuda a los bomberos a localizar rápidamente tu domicilio en caso de emergencia.",
                style: TextStyle(fontSize: 12, color: Colors.orange, height: 1.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                "Si tienes problemas con ubicar tu residencia, tu mismo ingresa su coordenada",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => setState(() => _showManualCoords = !_showManualCoords),
              child: Text(
                _showManualCoords ? "Ocultar coordenadas" : "Ingresar coordenadas",
                style: const TextStyle(fontSize: 12, color: Color(0xFF00A84E)),
              ),
            ),
          ],
        ),
        if (_showManualCoords) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0E3FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ingresar coordenadas manualmente",
                  style: TextStyle(color: Color(0xFF2C5BA9), fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 16),
                const Text("Latitud *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                const TextField(
                  decoration: InputDecoration(
                    hintText: "-33.4489",
                    fillColor: Colors.white,
                  ),
                ),
                const Text("Ejemplo: -33.4489 (coordenada Y)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 12),
                const Text("Longitud *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                const TextField(
                  decoration: InputDecoration(
                    hintText: "-70.6693",
                    fillColor: Colors.white,
                  ),
                ),
                const Text("Ejemplo: -70.6693 (coordenada X)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 16),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.vpn_key_outlined, size: 14, color: Color(0xFFD4AF37)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Puedes obtener las coordenadas desde Google Maps: haz clic derecho en tu ubicación y selecciona las coordenadas que aparecen.",
                        style: TextStyle(fontSize: 11, color: Color(0xFF2C5BA9), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                child: const Text("Anterior"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onNext,
                child: const Text("Continuar"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapButton(IconData icon) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon, size: 16, color: Colors.grey),
    );
  }
}
