import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';

class CameraPageDropOff extends StatefulWidget {

  final String? tripID;

  const CameraPageDropOff({super.key, required this.tripID});

  @override
  State<CameraPageDropOff> createState() => _CameraPageDropOffState();
}

class _CameraPageDropOffState extends State<CameraPageDropOff> {

  CommonMethods common = CommonMethods();
  XFile? pickupFile, destinationFile;
  String urlOfUploadedImage = "";

  uploadImageToDropOff() async
  {
    // use Date and Time to generate a unique ID for the image
    String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
    String jpg = ".jpg";
    String finalImageIDName = imageIDName + jpg;
    log("image name : $finalImageIDName");
    Reference referenceImage = FirebaseStorage.instance.ref().child("Images").child(finalImageIDName);
    UploadTask uploadTask = referenceImage.putFile(File(destinationFile!.path));
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();

    setState(() {
      urlOfUploadedImage;
    });
    return "done";
  }


  setImageToDatabaseDropOff() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
        const LoadingDialog(messageText: "Uploading Image"));

    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("tripRequests").child(widget.tripID!).child("dropOffPhoto");
    Map imageMap = {
      "dropOffPhoto" : urlOfUploadedImage,
    };
    usersRef.set(imageMap);
    Navigator.pop(context);
  }

  chooseImageFromGalleryDestination() async
  {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if(pickedFile != null)
    {
      setState(() {
        destinationFile = pickedFile;
      });
    }
    return "done";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Drop-Off proof of delivery"),
        centerTitle: true,
        leading: IconButton(
            onPressed: ()
            {
              Navigator.pop(context);
            }, icon: const Icon(Icons.arrow_back)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
        ),
        height: 1000,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    children:[

                Row(
                  children: [
                    const Text(
                      "Proof of Delivery image",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(width: 100,),

                      GestureDetector(
                        onTap: () async {
                          var responseFromChooseImageDestination = await chooseImageFromGalleryDestination();
                          if(responseFromChooseImageDestination == "done"){
                            var responseFromUploadImageDropOff = await uploadImageToDropOff();
                            if(responseFromUploadImageDropOff == "done"){
                              await setImageToDatabaseDropOff();
                            }
                          }
                        },
                        child: destinationFile == null ?
                        const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage("assets/images/No-image.jpg"),
                        ) : Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                            image: DecorationImage(
                              fit: BoxFit.fitHeight,
                              image: FileImage(
                                File(
                                  destinationFile!.path,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                  ],
                )
              ]
          ),
    ],
    ),
    ),
      ),
      );


  }
  @override
  bool get wantKeepAlive => true;
}

