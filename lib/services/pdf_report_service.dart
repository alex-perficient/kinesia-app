import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfReportService {
  static Future<void> generatePatientReport({
    required Map<String, dynamic> patientData,
    required List<QueryDocumentSnapshot> histories,
  }) async {
    final pdf = pw.Document();

    // Extraemos datos y calculamos edad
    final dob = patientData['dateOfBirth'] as Timestamp?;
    final age = _calculateAge(dob);

    // Variables Clínicas Avanzadas (Las que solicitaste integrar)
    final allergies = patientData['allergies'] ?? 'Negadas';
    final surgeries = patientData['surgeries'] ?? 'Ninguna reportada';
    final medications = patientData['medications'] ?? 'Ninguno actual';
    final pathologies = List<String>.from(
      patientData['pathologies'] ?? [],
    ).join(', ');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'KINES.IA - EXPEDIENTE CLÍNICO',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal800,
                    ),
                  ),
                  pw.Text(
                    'Mon TI Labs',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.teal300, thickness: 2),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) => [
          // 1. FICHA DE IDENTIFICACIÓN
          pw.Text(
            'DATOS DEL PACIENTE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                _buildRow(
                  'Nombre:',
                  patientData['fullName'] ?? 'N/A',
                  'Ocupación:',
                  patientData['occupation'] ?? 'N/A',
                ),
                pw.SizedBox(height: 8),
                _buildRow(
                  'Edad:',
                  age,
                  'Sexo:',
                  patientData['gender'] ?? 'N/A',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // 2. ANTECEDENTES MÉDICOS (El bloque completo)
          pw.Text(
            'ANTECEDENTES MÉDICOS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSingleRow(
                  'Patologías Crónicas:',
                  pathologies.isEmpty ? 'Ninguna' : pathologies,
                ),
                pw.SizedBox(height: 6),
                _buildSingleRow('Alergias:', allergies),
                pw.SizedBox(height: 6),
                _buildSingleRow('Cirugías Previas:', surgeries),
                pw.SizedBox(height: 6),
                _buildSingleRow('Medicamentos Actuales:', medications),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // 3. HISTORIAL DE CONSULTAS (Línea de tiempo)
          pw.Text(
            'EVOLUCIÓN CLÍNICA',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 10),
          ...histories.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date =
                (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
            final formattedDate =
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Fecha: $formattedDate',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _buildSingleRow(
                    'Diagnóstico:',
                    data['diagnosis'] ?? 'No especificado',
                  ),
                  pw.SizedBox(height: 4),
                  _buildSingleRow(
                    'Objetivos:',
                    data['objectives'] ?? 'No especificados',
                  ),
                  pw.SizedBox(height: 4),
                  _buildSingleRow(
                    'Zonas de Dolor:',
                    data['painZones'] ?? 'No especificadas',
                  ),
                ],
              ),
            );
          }),
        ],
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(color: PdfColors.grey),
            ),
          );
        },
      ),
    );

    // Muestra la vista previa del PDF para imprimir o compartir
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Expediente_${patientData['fullName'] ?? 'Paciente'}.pdf',
    );
  }

  // Helpers internos para el diseño del PDF
  static pw.Widget _buildRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '$label1 ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.TextSpan(text: value1),
              ],
            ),
          ),
        ),
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '$label2 ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.TextSpan(text: value2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSingleRow(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label ',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.TextSpan(
            text: value,
            style: const pw.TextStyle(color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  static String _calculateAge(Timestamp? dob) {
    if (dob == null) return 'N/A';
    final birthDate = dob.toDate();
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return '$age años';
  }
}
