extension type const SessionKey._(int _) {
  const SessionKey(int value) : this._(value);

  int get key => _;
}

extension type const EncryptionKey._(BigInt _) {
  const EncryptionKey(BigInt value) : this._(value);

  BigInt get key => _;
}
