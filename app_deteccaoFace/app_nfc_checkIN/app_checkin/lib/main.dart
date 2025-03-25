import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: NFCReaderScreen(),
    );
  }
}

class NFCReaderScreen extends StatefulWidget {
  @override
  _NFCReaderScreenState createState() => _NFCReaderScreenState();
}

class _NFCReaderScreenState extends State<NFCReaderScreen> {
  String nfcData = "Aproxime um cartão NFC";
  bool isReading = false;
  Map<String, dynamic> tagData = {};

  @override
  void initState() {
    super.initState();
    checkNFCAvailability();
  }

  Future<void> checkNFCAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() {
        nfcData = "NFC não disponível neste dispositivo.";
      });
    }
  }

  void startNFCSession() async {
    setState(() {
      nfcData = "Aproxime o cartão NFC...";
      isReading = true;
      tagData.clear();
    });

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          String tagId = await _extractTagData(tag);
          setState(() {
            nfcData = "Cartão NFC detectado! ID: $tagId";
          });
        } catch (e) {
          setState(() {
            nfcData = "Erro ao ler o cartão: $e";
          });
        } finally {
          NfcManager.instance.stopSession();
          setState(() {
            isReading = false;
          });
        }
      },
    );
  }

  Future<String> _extractTagData(NfcTag tag) async {
    String tagId = "";
    final nfcA = NfcA.from(tag);
    final nfcB = NfcB.from(tag);
    final nfcF = NfcF.from(tag);
    final nfcV = NfcV.from(tag);
    final isoDep = IsoDep.from(tag);
    
    if (nfcA != null) {
      tagId = _processNfcA(nfcA);
    } else if (nfcB != null) {
      tagId = _processNfcB(nfcB);
    } else if (nfcF != null) {
      tagId = _processNfcF(nfcF);
    } else if (nfcV != null) {
      tagId = _processNfcV(nfcV);
    } else if (isoDep != null) {
      tagId = _processIsoDep(isoDep);
    }

    tagData['ID'] = tagId;

    final ndef = Ndef.from(tag);
    if (ndef != null) {
      await _processNdef(ndef);
    } else {
      tagData['NDEF Suportado'] = 'Não';
    }

    return tagId;
  }

  String _processNfcA(NfcA nfcA) {
    final tagId = nfcA.identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
    tagData['Tipo'] = 'NFC-A (ISO 14443-A)';
    tagData['ATQA'] = nfcA.atqa.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    tagData['SAK'] = nfcA.sak.toRadixString(16).padLeft(2, '0');
    return tagId;
  }

  String _processNfcB(NfcB nfcB) {
    final tagId = nfcB.identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
    tagData['Tipo'] = 'NFC-B (ISO 14443-B)';
    tagData['Application Data'] = nfcB.applicationData.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    tagData['Protocol Info'] = nfcB.protocolInfo.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    return tagId;
  }

  String _processNfcF(NfcF nfcF) {
    final tagId = nfcF.identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
    tagData['Tipo'] = 'NFC-F (FeliCa)';
    tagData['System Code'] = nfcF.systemCode.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    return tagId;
  }

  String _processNfcV(NfcV nfcV) {
    final tagId = nfcV.identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
    tagData['Tipo'] = 'NFC-V (ISO 15693)';
    tagData['DSFID'] = nfcV.dsfId.toRadixString(16).padLeft(2, '0');
    return tagId;
  }

  String _processIsoDep(IsoDep isoDep) {
    final tagId = isoDep.identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
    tagData['Tipo'] = 'ISO-DEP';
    tagData['Historical Bytes'] = isoDep.historicalBytes?.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ') ?? 'N/A';
    return tagId;
  }

  Future<void> _processNdef(Ndef ndef) async {
    tagData['NDEF Suportado'] = 'Sim';
    tagData['NDEF Capacidade'] = '${ndef.cachedMessage?.byteLength ?? 0} bytes';
    tagData['NDEF Gravável'] = ndef.isWritable ? 'Sim' : 'Não';
    
    final ndefMessage = ndef.cachedMessage;
    if (ndefMessage != null && ndefMessage.records.isNotEmpty) {
      List<String> recordData = [];
      for (var i = 0; i < ndefMessage.records.length; i++) {
        final record = ndefMessage.records[i];
        recordData.add('Registro ${i + 1}: ${_decodeNdefRecord(record)}');
      }
      tagData['NDEF Registros'] = recordData.join('\n');
    } else {
      tagData['NDEF Registros'] = 'Nenhum registro NDEF encontrado';
    }
  }

  String _decodeNdefRecord(NdefRecord record) {
    if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
      if (record.type.isNotEmpty && String.fromCharCode(record.type[0]) == 'T') {
        int langLength = record.payload[0] & 0x3f;
        String text = String.fromCharCodes(record.payload.sublist(1 + langLength));
        return 'Texto: $text';
      } else if (record.type.isNotEmpty && String.fromCharCode(record.type[0]) == 'U') {
        String uri = String.fromCharCodes(record.payload.sublist(1));
        return 'URI: $uri';
      }
    }
    return 'Dados brutos: ${record.payload.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}';
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Leitor NFC")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      isReading ? Icons.nfc_rounded : Icons.contactless_rounded,
                      size: 48,
                      color: isReading ? Colors.blue : Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      nfcData,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: isReading ? null : startNFCSession,
                      icon: Icon(Icons.wifi),
                      label: Text(isReading ? "Lendo..." : "Iniciar Leitura NFC"),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (tagData.isNotEmpty) Expanded(
              child: Card(
                elevation: 4,
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    Text(
                      "Dados do Cartão",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    ...tagData.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${entry.key}:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${entry.value}",
                              style: TextStyle(
                                fontFamily: entry.key.contains('ID') || 
                                            entry.key.contains('NDEF Registros') ? 
                                            'monospace' : null,
                              ),
                            ),
                            Divider(height: 16),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}