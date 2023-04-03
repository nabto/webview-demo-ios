# Native iOS Nabto Edge Video Control App

Full example application showing how to display an RTSP stream from a Nabto Edge enabled device using the Nabto Edge Client SDK for iOS.

Precompiled version is not yet available.

## Prerequisites

You must download and install GStreamer package. Choose a version from <https://gstreamer.freedesktop.org/data/pkg/ios/>. The latest version that's been verified to work with this app is 1.22.0. GStreamer should by default be installed to `~/Library/Developer/GStreamer/iPhone.sdk`.

## Building

The app installs dependencies through Cocoapod, so to build and run, perform the following steps:

1. Install dependencies: `$ pod install` (see https://www.cocoapods.org for info on installation of the pod tool).

2. Open the generated workspace in XCode and work from there: `open NabtoEdgeVideo.xcworkspace`

## Simulator issues

The GStreamer package does as of writing not support M1 simulator builds. So either run on a physical iOS device. Or start XCode through Rosetta, this will build for and launch an x86_64 simulator instead of an arm64 based one.

## Questions?

In case of questions or problems, please write to support@nabto.com or contact us through the live chat on [www.nabto.com](https://www.nabto.com).