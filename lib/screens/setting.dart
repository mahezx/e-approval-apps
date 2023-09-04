import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imp_approval/data/data.dart';
import 'package:imp_approval/layout/mainlayout.dart';
import 'package:imp_approval/screens/detail/detail_infopribadi.dart';
import 'package:imp_approval/screens/detail/detail_privasi.dart';
import 'package:imp_approval/screens/detail/detail_faq.dart';
import 'package:imp_approval/screens/home.dart';
import 'package:imp_approval/screens/detail/detail_infoapp.dart';
import 'package:imp_approval/screens/request.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imp_approval/screens/login.dart';
import 'package:http/http.dart' as http;

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    TextEditingController _validpassController = TextEditingController();
    bool validasilogout = true;

    Future<void> logout() async {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      String? token = preferences.getString('token');
      var response = await http.post(
        Uri.parse(
            'https://4598-2404-8000-1027-303f-c12d-d823-f61-7b0.ngrok-free.app/api/logout'),
        body: {
          "validpassword": _validpassController.text,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        preferences.remove('token');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout gagal, Password Salah'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    Widget _modalvalidasilogout(BuildContext context) {
      return CupertinoAlertDialog(
        title: Text("Validasi Password",
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
        actions: [
          CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Batal",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: kTextBlocker,
                    fontWeight: FontWeight.w600,
                  ))),
          CupertinoDialogAction(
              onPressed: () {
                if (validasilogout) {
                  logout();
                  setState(() {
                    validasilogout = false;
                  });
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text("Kirim",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ))),
        ],
        content: Column(
          children: [
            Text(
                'Masukkan password saat ini untuk konfirmasi diri anda sebelum Logout.',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                )),
            SizedBox(height: 10),
            CupertinoTextField(
              controller: _validpassController,
              obscureText: true, // Gunakan status _isPasswordVisible
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              placeholder: 'Masukan password',
              placeholderStyle: GoogleFonts.montserrat(
                fontSize: 14,
                color: kTextgrey,
                fontWeight: FontWeight.w500,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: greyText, width: 0.5),
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      );
    }

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: kBackground3,
          appBar: AppBar(
            backgroundColor: Colors.white, // Menghilangkan background color
            title: Text(
              'Settings',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: MediaQuery.of(context).size.width * 0.04,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            elevation: 0,
          ),
          body: SafeArea(
            child: ListView(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      color: Colors.white,
                      child: Row(
                        children: [
                          // card profile \\
                          Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset('assets/img/profil2.png',
                                  height: 58, width: 58),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 20), // Add vertical padding
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fauzan Alghifari',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  'Backend developer',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    // list menu setting \\
                    Column(
                      children: [
                        // informasi pribadi
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InformasiPribadi(),
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.user,
                                        color: kTextgrey,
                                      ),
                                      SizedBox(
                                        width: 15,
                                      ),
                                      Container(
                                        child: Row(
                                          children: [
                                            Text('Informasi Pribadi',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  color: kTextgrey,
                                                  fontWeight: FontWeight.w500,
                                                )),
                                          ],
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        LucideIcons.chevronRight,
                                        color: kBorder,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width - 55,
                                  height: 1,
                                  color: kBorder,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // informasi notifikasi
                        InkWell(
                          onTap: () {
                            // Tambahkan aksi yang ingin Anda lakukan ketika widget ditekan
                          },
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.bell,
                                        color: kTextgrey,
                                      ),
                                      SizedBox(
                                        width: 15,
                                      ),
                                      Container(
                                        child: Row(
                                          children: [
                                            Text('Notifikasi',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  color: kTextgrey,
                                                  fontWeight: FontWeight.w500,
                                                )),
                                          ],
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        LucideIcons.chevronRight,
                                        color: kBorder,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width - 55,
                                  height: 1,
                                  color: kBorder,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // informasi privasi
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrivasiPage(),
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.shield,
                                        color: kTextgrey,
                                      ),
                                      SizedBox(
                                        width: 15,
                                      ),
                                      Container(
                                        child: Row(
                                          children: [
                                            Text('Privasi',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  color: kTextgrey,
                                                  fontWeight: FontWeight.w500,
                                                )),
                                          ],
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        LucideIcons.chevronRight,
                                        color: kBorder,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width - 55,
                                  height: 1,
                                  color: kBorder,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // informasi aplikasi
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InfoApp(),
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.info,
                                        color: kTextgrey,
                                      ),
                                      SizedBox(
                                        width: 15,
                                      ),
                                      Container(
                                        child: Row(
                                          children: [
                                            Text('Informasi Aplikasi',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  color: kTextgrey,
                                                  fontWeight: FontWeight.w500,
                                                )),
                                          ],
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        LucideIcons.chevronRight,
                                        color: kBorder,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width - 55,
                                  height: 1,
                                  color: kBorder,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Faq
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FaqScreen(),
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.helpCircle,
                                        color: kTextgrey,
                                      ),
                                      SizedBox(
                                        width: 15,
                                      ),
                                      Container(
                                        child: Row(
                                          children: [
                                            Text('Faq',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  color: kTextgrey,
                                                  fontWeight: FontWeight.w500,
                                                )),
                                          ],
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        LucideIcons.chevronRight,
                                        color: kBorder,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width - 55,
                                  height: 1,
                                  color: kBorder,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // keluar
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (validasilogout)
                                      _modalvalidasilogout(context),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.logOut,
                                        color: kTextgrey,
                                      ),
                                      SizedBox(
                                        width: 15,
                                      ),
                                      Container(
                                        child: Row(
                                          children: [
                                            Text('Keluar',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  color: kTextgrey,
                                                  fontWeight: FontWeight.w500,
                                                )),
                                          ],
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        LucideIcons.chevronRight,
                                        color: kBorder,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width - 55,
                                  height: 1,
                                  color: kBorder,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}