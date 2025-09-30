import 'package:flutter/material.dart';
import 'package:ericsson/main.dart';

class DaftarMenu extends StatelessWidget {
  final String namaMinuman;
  final int harga;

  const DaftarMenu({Key? key, required this.namaMinuman, required this.harga})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color.fromARGB(255, 104, 98, 89), width: 1),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                  )
                ],
              ),
              Column(
                children: [Text(namaMinuman), Text('Rp. $harga')],
              ),
              const Row(
                children: [Icon(Icons.arrow_right)],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.menu),
            ]),
            const Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('How do you like your coffe?'),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                children: [
                  DaftarMenu(namaMinuman: "Long Black", harga: 15000),
                  SizedBox(height: 10),
                  DaftarMenu(namaMinuman: "Espresso", harga: 20000),
                  SizedBox(height: 10),
                  DaftarMenu(namaMinuman: "Americano", harga: 20000),
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              label: 'Menu',
            ),
          ],
          onTap: (value) => {
                if (value == 0)
                  {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MainApp(),
                      ),
                    )
                  }
              }),
    );
  }
}
