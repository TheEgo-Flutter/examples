import 'package:flutter/material.dart';
import 'package:render/render.dart';

class NavigationControls extends StatelessWidget {
  final void Function() motionRenderCallback;
  final void Function() imageRenderCallback;
  final Stream<RenderNotifier>? stream;

  const NavigationControls({
    Key? key,
    required this.imageRenderCallback,
    required this.motionRenderCallback,
    required this.stream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<RenderNotifier>(
              stream: stream?.where((event) => !event.isLog),
              builder: (context, snapshot) {
                if (snapshot.data?.isActivity == true && !snapshot.data!.isResult) {
                  final activity = snapshot.data as RenderActivity;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Render activity:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("Operation: ${activity.state.name}"),
                      Text("Message: ${activity.message}"),
                      Text("TimeRemaining: ${activity.timeRemaining}"),
                      Text("TotalExpectedTime: ${activity.totalExpectedTime}"),
                      Text("ProgressPercentage: ${activity.progressPercentage * 100}%"),
                      Text("Current time: ${activity.timestamp}"),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: LinearProgressIndicator(
                          value: activity.progressPercentage,
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.data?.isError == true) {
                  final error = snapshot.data as RenderError;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Render Error:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("fatal: ${error.fatal}"),
                      Text("Message: ${error.exception.message}"),
                    ],
                  );
                } else {
                  return Container();
                }
              }),
        ),
        Center(
          child: Wrap(
            children: [
              TextButton(
                  onPressed: () {
                    motionRenderCallback();
                  },
                  child: const Text("Capture motion")),
              TextButton(
                  onPressed: () {
                    imageRenderCallback();
                  },
                  child: const Text("Capture image")),
            ],
          ),
        ),
      ],
    );
  }
}
