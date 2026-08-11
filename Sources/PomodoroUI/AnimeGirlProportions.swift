import CoreGraphics

/// Every dimension of the anime girl, as named numbers instead of coordinates.
///
/// The art used to be ~60 hardcoded path strings. That made "her chin is too
/// pointy" a hunt through eight control points, and the only way to see what a
/// change did was to render it — which is how a face that measured correctly
/// still ended up looking gaunt. Here the same edit is `chinTaper: 0.7`.
///
/// The values are baked once into `AnimeGirlArt.layers` at load, so this costs
/// nothing at draw time and every existing contract (`RigView`, `RigSubject`,
/// the rig tests, all three performances) is untouched. `AnimeGirlParts.build`
/// is a pure function of this struct, so a tool can call it with different
/// values for a live preview without any of that changing.
///
/// Vertical values are canvas units measured from the top, matching the 200×260
/// design space. Widths are full widths, not half-widths.
public struct AnimeGirlProportions: Equatable, Sendable {

    // MARK: - Vertical landmarks

    /// Top of the skull, excluding hair.
    public var crown: Double
    public var chin: Double
    /// Where the shoulder line crosses the torso.
    public var shoulder: Double
    public var elbow: Double
    public var wrist: Double
    /// Narrowest point of the torso.
    public var waist: Double
    /// Where the legs separate from the hips.
    public var hip: Double
    /// Top of the boot shaft.
    public var bootTop: Double
    public var sole: Double

    // MARK: - Head

    public var headWidth: Double
    /// 0 = a rounded jaw with no chin, 1 = the sharp wedge of the first draft.
    /// This is the single biggest control on how gaunt she reads.
    public var chinTaper: Double
    /// 0 = a flat-topped cap, 1 = a fully domed cranium.
    public var skullRound: Double
    public var neckWidth: Double

    // MARK: - Eyes

    /// Eye height as a fraction of face height. Adult anime leads sit near 0.20;
    /// below ~0.17 reads gaunt, above ~0.22 reads child.
    public var eyeHeightRatio: Double
    public var eyeAspect: Double
    /// Gap between the two inner corners.
    public var eyeGap: Double
    /// Iris height as a fraction of eye height.
    public var irisFill: Double
    /// Thickness of the upper lash line. Does more aging work than eye size.
    public var lidWeight: Double

    // MARK: - Hair

    /// How far the crown puffs beyond the skull.
    public var hairVolume: Double
    /// How far down the forehead the fringe reaches, as a fraction of the gap
    /// between crown and brow. Above ~0.8 it becomes blunt bangs, which read young.
    public var fringeDepth: Double
    public var tailRootWidth: Double
    public var tailWidth: Double
    public var tailTipWidth: Double
    /// How far the tail sweeps away from the head before it falls.
    public var tailFlare: Double
    /// Where the tail hands off from base to tip.
    public var tailHandoff: Double
    public var tailEnd: Double
    /// 0 = falls straight, 1 = curls strongly back under itself.
    public var tailCurl: Double
    public var sideLockWidth: Double
    public var sideLockEnd: Double

    // MARK: - Body

    /// Widest point of the ribcage.
    public var ribWidth: Double
    public var waistWidth: Double
    public var hipWidth: Double
    /// Width across the top of the torso, before the arms add their deltoids.
    public var torsoTopWidth: Double
    /// How far the deltoid pushes past the torso on each side. Shoulder span
    /// relative to head width is *the* adult-vs-child tell: ~1.6 adult, ~1.1 child.
    public var deltoid: Double
    public var upperArmWidth: Double
    public var foreArmWidth: Double
    public var thighWidth: Double
    public var bootWidth: Double
    /// Subtle contour on the top so it does not read as cardboard. Kept low
    /// deliberately — this is form, not emphasis.
    public var chestDepth: Double

    // MARK: - Outfit

    public var topHem: Double
    public var skirtHem: Double
    public var skirtFlare: Double
    public var pleats: Int

    // MARK: - Derived

    public var faceHeight: Double { chin - crown }
    public var shoulderSpan: Double { torsoTopWidth + deltoid * 2 }
    /// Eye centres sit on the skull midline, where an adult's do.
    public var eyeLine: Double { crown + faceHeight * 0.527 }
    public var eyeHeight: Double { faceHeight * eyeHeightRatio }
    public var eyeWidth: Double { eyeHeight * eyeAspect }
    public var browLine: Double { eyeLine - eyeHeight * 0.79 }

    /// The shipped figure: ~5.9 heads, shoulders 1.65 head-widths, waist 0.67 of
    /// shoulders, legs 0.48 of height. Adult on every ratio that matters.
    public static let standard = AnimeGirlProportions(
        crown: 26, chin: 63.5,
        shoulder: 76, elbow: 112, wrist: 140,
        waist: 119, hip: 136, bootTop: 170, sole: 239,

        headWidth: 28, chinTaper: 1.0, skullRound: 1.0, neckWidth: 10.4,

        eyeHeightRatio: 0.195, eyeAspect: 1.29, eyeGap: 6.0,
        irisFill: 0.93, lidWeight: 1.9,

        hairVolume: 6.0, fringeDepth: 0.62,
        tailRootWidth: 5, tailWidth: 12, tailTipWidth: 10,
        tailFlare: 8, tailHandoff: 96, tailEnd: 166, tailCurl: 0.45,
        sideLockWidth: 6.4, sideLockEnd: 72,

        ribWidth: 37, waistWidth: 31, hipWidth: 38, torsoTopWidth: 30,
        deltoid: 8, upperArmWidth: 7.6, foreArmWidth: 8, thighWidth: 10,
        bootWidth: 10.6, chestDepth: 0.35,

        topHem: 108.5, skirtHem: 157, skirtFlare: 6, pleats: 4
    )
}
