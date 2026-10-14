import Foundation

/// Outils de découpage de paragraphes partagés par les cibles.
public enum TextUtils {

    /// Plages des paragraphes successifs d'une chaîne (équivalent
    /// de getParagraphStart, compatible avec l'overlay Swift actuel).
    public static func paragraphRanges(of s: String, length: Int) -> [NSRange] {
        guard length > 0 else { return [] }
        let ns = s as NSString
        var ranges: [NSRange] = []
        var start = 0
        while start < length {
            let r = ns.lineRange(for: NSRange(location: start, length: 0))
            if r.length == 0 {
                ranges.append(NSRange(location: start, length: length - start))
                break
            }
            ranges.append(r)
            start = NSMaxRange(r)
        }
        return ranges
    }
}
