import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage>
{
  String driverEarnings = "";

  getTotalEarningsOfCurrentDriver() async
  {
    DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("drivers");

    await driversRef.child(FirebaseAuth.instance.currentUser!.uid)
        .once()
        .then((snap)
    {
      if((snap.snapshot.value as Map)["earnings"] != null)
      {
        setState(() {
          driverEarnings = (((snap.snapshot.value as Map)["earnings"])*55.95).toString();
        });
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getTotalEarningsOfCurrentDriver();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Center(

            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green.shade200,
                        Colors.green.shade300,
                        Colors.green.shade400,
                        Colors.green.shade500,
                      ],
                      stops: const [
                        0.1,
                        0.3,
                        0.9,
                        1.0
                      ])
              ),
              width: MediaQuery.of(context).size.width,
              height: (MediaQuery.of(context).size.height) - 100,
              child: Padding(
                padding: const EdgeInsets.all(55.0),
                child: Column(
                  children: [

                    Image.asset("assets/images/earningsicon.png", width: 120,),

                    const SizedBox(
                      height: 10,
                    ),

                    const Text(
                      "Total Earnings:",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),

                    Container(
                      width: 300,
                      height: 150,
                      padding: const EdgeInsets.all(15.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.green], // Example gradient colors
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10), // Optional: Add border radius for rounded corners
                      ),
                      child: Text(
                        "\₱ ${driverEarnings}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
