Amazon Fling SDK
===============

Amazon Fling enables you to use apps on your iOS, Android, and Fire OS based mobile 
devices to control digital media playback on the Amazon Fire TV. Using this SDK, you can 
develop applications that use this feature.  

Contents of the package
=======================

Android SDK (android-sdk)
-------------------------
 - lib: Contains the AmazonFling.JAR library as well as dependencies needed for 
        non-Fire OS Android devices
 - api-docs: Java API docs in HTML format
 - samples
   - CustomPlayerSample: This is a custom sample player application that can be installed
                         on the Amazon Fire TV
   - FlingSample: This is a sample controller application that can discover the devices
                 on which the player application is installed
   - MediaRouteProvider: The controller app that uses the MediaRouteProvider available
                         in this SDK to control the player
   - CastWithFlingExample: A controller app that supports Chromecast and Fire TV

iOS SDK (ios-sdk)
-----------------
 - frameworks: Contains the AmazonFling.framework for iOS applications
   - third_party_framework: Dependencies needed for this SDK
 - api-docs: API Documentation in browsable docset format. You can copy this docset 
             package to ~/Library/Developer/Shared/Documentation/DocSets for offline 
             viewing in XCode "Documentation and API Reference"
 - samples
   - FlingSample: A simple controller app that discovers and controls devices with a
                  player app installed
   - CastHelloVideo-ios-master: The Google Cast sample app for iOS modified to discover 
                                and control Amazon Fire TV devices

More Information
================
1. Developer Portal: https://developer.amazon.com/public/apis/experience/fling
   On the developer portal, you can find in-depth documentation related to this SDK, 
   such as tutorials and the latest API docs.
2. Developer Forum: https://forums.developer.amazon.com/forums/category.jspa?categoryID=61
   Participate in technical discussions with other developers and get support on the 
   forum.
