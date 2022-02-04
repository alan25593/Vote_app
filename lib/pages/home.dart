import 'package:appband/models/band.dart';
import 'package:appband/services/socket_services.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:pie_chart/pie_chart.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', (payload) {
      this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();

      setState(() {});
    });

    super.initState();
  }

/*
  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }*/

  @override
  Widget build(BuildContext context) {
    // conexión con services socket check visual de conexión con el server
    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Bandas')),
        actions: [
          //check visual de conexión con el server
          Container(
              margin: EdgeInsets.only(right: 10),
              child: (socketService.serverStatus == ServerStatus.Online)
                  ? Icon(
                      Icons.check_circle,
                      color: Colors.green[300],
                    )
                  : Icon(
                      Icons.offline_bolt,
                      color: Colors.red,
                    ))
        ],
      ),
      body: Column(
        children: [
          _showGraph(context),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, index) => bandTile(bands[index]),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: addNewBand,
      ),
    );
  }

  Widget bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.lime[50],
        child: Align(
          child: Text('Deslizar para eliminar'),
        ),
      ),
      onDismissed: (_) {
        _toast(context);
        //emitir : delete-band
        socketService.emit('delete-band', {'id': band.id});
      },
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0, 2)),
          backgroundColor: Colors.lime,
        ),
        title: Text(band.name),
        trailing: Text(
          '${band.votes}',
          style: TextStyle(fontSize: 20),
        ),
        onTap: () {
          socketService.socket.emit('vote-band', {'id': band.id});
        },
      ),
    );
  }

  _toast(context) {
    return Fluttertoast.showToast(
        msg: "Borrado con éxito!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.white,
        textColor: Colors.lime[50],
        fontSize: 12.0);
  }

  addNewBand() {
    final textController = new TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar:'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Detalle',
                    icon: Icon(
                      Icons.people_outline_rounded,
                      color: Colors.lime,
                    )),
              ),
              /*  TextField(
                decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    hintText: 'Saldo',
                    icon: Icon(
                      Icons.monetization_on,
                      color: Colors.lime,
                    )),
                keyboardType: TextInputType.number,
                controller: textController2,
              ),*/
            ],
          ),
          actions: [
            MaterialButton(
              textColor: Colors.red,
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            MaterialButton(
              color: Colors.lime,
              textColor: Colors.white,
              child: Text('Guardar'),
              onPressed: () => addBandToList(textController.text
                  // , textController2.text
                  ),
            )
          ],
        );
      },
    );
  }

  void addBandToList(
    String name,
    /* String vote*/
  ) {
    if (name.length > 1) {
      //emitir :  add-band
      //{name: 'name'}
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.socket.emit('add-band', {'name': name});
      Navigator.pop(context);
    }
  }

  _showGraph(context) {
    Map<String, double> dataMap = new Map();
    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });
    return Container(
        padding: EdgeInsets.only(top: 10),
        width: double.infinity,
        height: 200,
        child: PieChart(
          dataMap: dataMap,
          chartType: ChartType.ring,
        ));
  }
}
