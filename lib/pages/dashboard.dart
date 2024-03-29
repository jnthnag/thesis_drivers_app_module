import 'package:flutter/material.dart';
import 'package:thesis_drivers_app_module/pages/earnings_page.dart';
import 'package:thesis_drivers_app_module/pages/home_page.dart';
import 'package:thesis_drivers_app_module/pages/profile_page.dart';
import 'package:thesis_drivers_app_module/pages/trips_page.dart';
import 'package:thesis_drivers_app_module/models/trip_details.dart';

class Dashboard extends StatefulWidget
{
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}



class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin
{
  TabController? controller;
  int indexSelected = 0;


  onBarItemClicked(int i)
  {
    setState(() {
      indexSelected = i;
      controller!.index = indexSelected;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    controller = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller!.dispose();
    super.dispose();
  }

  // Start widget build
  @override
  Widget build(BuildContext context)
  {
    TripDetails? tripDetailsInfo;
    return Scaffold(
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children:  [
          HomePage(tripDetailsInfo: tripDetailsInfo,),
          const EarningsPage(),
          const TripsPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const 
        [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.credit_card),
              label: "Earnings"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_tree),
              label: "Trips"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile"
          ),
        ],
        currentIndex: indexSelected,
        //backgroundColor: Colors.grey,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.green,
        showSelectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        onTap: onBarItemClicked,
      )
    );
  }
}
