String formatClock(int totalSeconds) {
  final seconds = totalSeconds < 0 ? 0 : totalSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:${two(minutes)}:${two(secs)}' : '${two(minutes)}:${two(secs)}';
}

String formatDuration(int totalSeconds) {
  final seconds = totalSeconds < 0 ? 0 : totalSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0 && minutes > 0) {
    return '$hours 小时 $minutes 分';
  }
  if (hours > 0) {
    return '$hours 小时';
  }
  if (minutes > 0) {
    return '$minutes 分钟';
  }
  return '$seconds 秒';
}
