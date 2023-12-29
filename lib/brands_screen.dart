import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clientflow/data/brand_data.dart';

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key});

  @override
  _BrandScreenState createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  late List<BrandData> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _brands = await fetchBrands();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: Text(
          'Brands',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 76, 135),
      ),
      body: _brands.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _brands.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        _brands[index].brand,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context, _brands[index].id);
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
