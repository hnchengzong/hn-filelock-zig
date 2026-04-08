pub fn xor(data: []u8, key: []const u8) void {
    const key_len = key.len;
    for (0..data.len) |i| {
        data[i] ^= key[i % key_len];
    }
}

pub fn add_encrypt(data: []u8, key: []const u8) void {
    const kl = key.len;
    for (0..data.len) |i| {
        data[i] = data[i] +% key[i % kl];
        data[i] = (data[i] << 1) | (data[i] >> 7);
    }
}

pub fn add_decrypt(data: []u8, key: []const u8) void {
    const kl = key.len;
    for (0..data.len) |i| {
        data[i] = (data[i] >> 1) | (data[i] << 7);
        data[i] = data[i] -% key[i % kl];
    }
}
