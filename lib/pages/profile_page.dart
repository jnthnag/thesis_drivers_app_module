import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../authentication/login_screen.dart';
import '../global/global_var.dart';
import '../methods/common_methods.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
{
  CommonMethods common = CommonMethods();

  setDriverInfo()
  {
    setState(() {
      common.userNameTextEditingController.text = driverName;
      common.userPhoneTextEditingController.text = driverPhone;
      common.emailTextEditingController.text = FirebaseAuth.instance.currentUser!.email.toString();
      common.carTextEditingController.text = "$carPlateNumber - $carColor - $carModel";
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    setDriverInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
        gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue, Colors.yellowAccent], // Adjust colors as needed
    ),
    ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              //image
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                    image: DecorationImage(
                      fit: BoxFit.fitHeight,
                      image: NetworkImage(
                        driverPhoto,
                      ),
                    )
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              //driver name
              Padding(
                padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 8),
                child: TextField(
                  controller: common.userNameTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: false,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF61A3BA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              //driver phone
              Padding(
                padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 4),
                child: TextField(
                  controller: common.userPhoneTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: false,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF61A3BA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.phone_android_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              //driver email
              Padding(
                padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 4),
                child: TextField(
                  controller: common.emailTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: false,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF61A3BA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.email,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              //driver car info
              Padding(
                padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 4),
                child: TextField(
                  controller: common.carTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: false,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF61A3BA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.drive_eta_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              //logout btn
              ElevatedButton(
                onPressed: ()
                {
                  FirebaseAuth.instance.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c)=> const LoginScreen()));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 18)
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
                  ),


                ),
              ),

            ],
          ),
        ),
      ),
    ),);
  }
}
