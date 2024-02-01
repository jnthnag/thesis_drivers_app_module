import 'dart:async';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:thesis_drivers_app_module/models/trip_details.dart';
import '../global/global_var.dart';


class NotificationDialog extends StatefulWidget {
  TripDetails? tripDetailsInfo;

  NotificationDialog({super.key, this.tripDetailsInfo});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog>
{
  String tripRequestStatus = "";

  cancelNotificationDialogAfter20Sec()
  {
    const oneTickPerSecond = Duration(seconds: 1);
    var timerCountDown = Timer.periodic(oneTickPerSecond, (timer)
    {
      driverTripRequestTimeout = driverTripRequestTimeout - 1;

      if(tripRequestStatus == "accepted")
        {
          timer.cancel();
          driverTripRequestTimeout = 20;
        }

      if(driverTripRequestTimeout == 0)
        {
          Navigator.pop(context);
          timer.cancel();
          driverTripRequestTimeout = 20;
        }
    });
  }

  @override
  void initState() {
    super.initState();

    cancelNotificationDialogAfter20Sec();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.black54,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.black54, borderRadius: BorderRadius.circular(4)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 30,
            ),

            Image.asset(
              "assets/image/uberexec.png",
              width: 140,
            ),

            const SizedBox(
              height: 16,
            ),

            //title

            const Text(
              "NEW TRIP REQUEST",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey),
            ),

            const SizedBox(
              height: 20,
            ),

            const Divider(
              height: 1,
              color: Colors.white,
              thickness: 1,
            ),

            const SizedBox(
              height: 10,
            ),

            //pickup address and drop-off address widget icon
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  //pickup
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        "assets/images/initial.png",
                        height: 16,
                        width: 16,
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo!.pickUpAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  //dropOff
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        "assets/images/final.png",
                        height: 16,
                        width: 16,
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo!.dropOffAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Divider(
              height: 1,
              color: Colors.white,
              thickness: 1,
            ),

            const SizedBox(
              height: 10,
            ),
            //decline and accept button
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // notification stop
                        audioPlayer.stop();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink),
                      child: const Text(
                        "DECLINE",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: ()
                      {
                        // notification sound
                        audioPlayer.stop();

                        setState(() {
                          tripRequestStatus = "accepted";
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text(
                        "ACCEPT",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
