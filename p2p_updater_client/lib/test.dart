import 'dart:io';

Future<String> getIp(bool bInShortForm) async {
  String IPs = '';
  for (var interface in await NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (!addr.isLoopback) {
        if (bInShortForm) {
          IPs += '${addr.address};';
        } else {
          IPs += "{ 'type': '${addr.type.name}', 'addr': '${addr.address}' }, ";
        }
      }
    }
  }

  if (bInShortForm) {
    IPs = IPs.substring(0, IPs.length - 1);
    return IPs;
  } else {
    IPs = IPs.substring(0, IPs.length - 2);
    return "[ $IPs ]";
  }
}

void main() async {
  final ips = await getIp(true);
  print(ips);
}
