import Foundation

/// Conteneur ZIP minimal (méthode stockage, sans compression),
/// suffisant pour produire des paquets Office Open XML valides.
public enum Zip {

    public static let crcTable: [UInt32] = {
        (0..<256).map { n -> UInt32 in
            var c = UInt32(n)
            for _ in 0..<8 {
                c = (c & 1 == 1) ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()

    public static func crc32(_ bytes: [UInt8]) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for b in bytes {
            crc = (crc >> 8) ^ crcTable[Int((crc ^ UInt32(b)) & 0xFF)]
        }
        return crc ^ 0xFFFFFFFF
    }

    public static func build(_ files: [(name: String, data: [UInt8])]) -> Data {
        var out = Data()
        var central = Data()
        var offset: UInt32 = 0

        for file in files {
            let name = Array(file.name.utf8)
            let data = file.data
            let crc = crc32(data)
            let size = UInt32(data.count)

            // En-tête local (30 octets)
            out.appendLE(UInt32(0x04034B50))
            out.appendLE(UInt16(20))
            out.appendLE(UInt16(0))
            out.appendLE(UInt16(0)) // méthode : stockage
            out.appendLE(UInt16(0))
            out.appendLE(UInt16(0x21))
            out.appendLE(crc)
            out.appendLE(size)
            out.appendLE(size)
            out.appendLE(UInt16(name.count))
            out.appendLE(UInt16(0))
            out.append(contentsOf: name)
            out.append(contentsOf: data)

            // Enregistrement central
            central.appendLE(UInt32(0x02014B50))
            central.appendLE(UInt16(20))
            central.appendLE(UInt16(20))
            central.appendLE(UInt16(0))
            central.appendLE(UInt16(0))
            central.appendLE(UInt16(0))
            central.appendLE(UInt16(0x21))
            central.appendLE(crc)
            central.appendLE(size)
            central.appendLE(size)
            central.appendLE(UInt16(name.count))
            central.appendLE(UInt16(0))
            central.appendLE(UInt16(0))
            central.appendLE(UInt16(0))
            central.appendLE(UInt16(0))
            central.appendLE(UInt32(0))
            central.appendLE(offset)
            central.append(contentsOf: name)

            offset += UInt32(30 + name.count + data.count)
        }

        let centralSize = UInt32(central.count)
        out.append(central)

        // Fin de répertoire central (22 octets)
        out.appendLE(UInt32(0x06054B50))
        out.appendLE(UInt16(0))
        out.appendLE(UInt16(0))
        out.appendLE(UInt16(files.count))
        out.appendLE(UInt16(files.count))
        out.appendLE(centralSize)
        out.appendLE(offset)
        out.appendLE(UInt16(0))
        return out
    }
}

private extension Data {
    mutating func appendLE(_ v: UInt16) {
        append(UInt8(v & 0xFF))
        append(UInt8((v >> 8) & 0xFF))
    }
    mutating func appendLE(_ v: UInt32) {
        append(UInt8(v & 0xFF))
        append(UInt8((v >> 8) & 0xFF))
        append(UInt8((v >> 16) & 0xFF))
        append(UInt8((v >> 24) & 0xFF))
    }
}
