import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InputForm extends StatefulWidget {
  InputForm(this.document);
  final DocumentSnapshot document;

  @override
  _MyInputFormState createState() => _MyInputFormState();
}

class _FormData {
  String borrowOrLend = "borrow";
  String user;
  String stuff;
  DateTime date = DateTime.now();
}

class _MyInputFormState extends State<InputForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _FormData _data = _FormData();

  Future <DateTime> _selectTime(BuildContext context) {
    return showDatePicker(
      context: context,
      initialDate: _data.date,
      firstDate: DateTime(_data.date.year - 2),
      lastDate: DateTime(_data.date.year + 2),
    );
  }

  void _setLendOrRent(String value) {
    setState(() {
      _data.borrowOrLend = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference _mainReference;
    _mainReference = FirebaseFirestore.instance.collection('kashikari-memo').doc();

    bool canDelete = false;

    if (widget.document != null) {
      // 既にデータが存在する場合
      if (_data.user == null && _data.stuff == null) {
        _data.borrowOrLend = widget.document['borrowOrLend'];
        _data.user = widget.document['user'];
        _data.stuff = widget.document['stuff'];
        _data.date = widget.document['date'].toDate();
      }

      _mainReference = FirebaseFirestore.instance.collection('kashikari-memo').doc(widget.document.id);
      canDelete = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('貸し借り入力'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                print("保存ボタンを押しました");
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                  _mainReference.set(
                    {
                      'borrowOrLend': _data.borrowOrLend,
                      'user': _data.user,
                      'stuff': _data.stuff,
                      'date': _data.date
                    },
                    SetOptions(merge: true),
                  );
                  Navigator.pop(context);
                }
              }
          ),
          IconButton(
              icon: Icon(Icons.delete),
              onPressed: !canDelete? null:() {
                print("削除ボタンを押しました");
                _mainReference.delete();
                Navigator.pop(context);
              }
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.person),
                  hintText: '相手の名前',
                  labelText: '誰に',
                ),
                onSaved: (String value) {
                  _data.user = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return '名前は必須入力項目です';
                  }
                },
                initialValue: _data.user,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.business_center),
                  hintText: '借りたもの、貸したもの',
                  labelText: '何を',
                ),
                onSaved: (String value) {
                  _data.stuff = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return '借りたもの、貸したものは必須入力項目です';
                  }
                },
                initialValue: _data.stuff,
              ),
              RadioListTile(
                value: "borrow",
                groupValue: _data.borrowOrLend,
                title: Text("借りた"),
                onChanged: (String value) {
                  print("借りたを押しました");
                  _setLendOrRent(value);
                },
              ),
              RadioListTile(
                value: "lend",
                groupValue: _data.borrowOrLend,
                title: Text("貸した"),
                onChanged: (String value) {
                  print("貸したを押しました");
                  _setLendOrRent(value);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("期限: ${_data.date.toString().substring(0, 10)}"),
              ),
              RaisedButton(
                child: const Text("締め切り日変更"),
                onPressed: () {
                  print("締め切り日変更をタップしました");
                  _selectTime(context).then((time) {
                    if (time != null && time != _data.date) {
                      setState(() {
                        _data.date = time;
                      });
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
