import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_application/provider/order.dart' as ord;

class OrderItem extends StatefulWidget {
  final ord.Order? order;
  const OrderItem({this.order});

  @override
  State<OrderItem> createState() => _OrderItemState();
}

class _OrderItemState extends State<OrderItem> {
  bool _isExpaneded = false;
  @override
  Widget build(BuildContext context) {
    return Card(
        margin: EdgeInsets.all(10),
        child: Column(
          children: [
            ListTile(
              title: Text('\$${widget.order!.amount}'),
              subtitle: Text(
                DateFormat('dd MM yyyy hh:mm').format(widget.order!.datetime!),
              ),
              trailing: IconButton(
                icon:
                    Icon(_isExpaneded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isExpaneded = !_isExpaneded;
                  });
                },
              ),
            ),
            AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: _isExpaneded
                    ? min(widget.order!.products!.length * 20.0 + 50, 100)
                    : 0,
                child: ListView(
                  children: widget.order!.products!
                      .map((prod) => Row(
                            children: [
                              Text("${prod!.title!}"),
                              const Spacer(),
                              Text("${prod!.quantity!}"),
                              Text("\$${prod!.price}"),
                            ],
                          ))
                      .toList(),
                ))
          ],
        ));
  }
}
