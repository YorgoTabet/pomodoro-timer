import CoreGraphics

/// Every dimension of Power (the character still called `AnimeGirl` in code), as
/// named numbers instead of coordinates.
///
/// The art used to be ~60 hardcoded path strings. That made "her chin is too
/// pointy" a hunt through eight control points, and the only way to see what a
/// change did was to render it. Here the same edit is `chinTaper: 0.7`.
///
/// The values are baked once into `AnimeGirlArt.layers` at load, so this costs
/// nothing at draw time. `AnimeGirlArt.build` is a pure function of this struct,
/// so a tool can call it with different values for a live preview.
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
    /// Narrowest point of the torso, and where the slacks' waistband sits.
    public var waist: Double
    /// Where the legs separate from the hips.
    public var hip: Double
    public var knee: Double
    /// Bottom of the rolled trouser cuff, at mid-calf. Bare shin shows below it.
    public var cuff: Double
    /// Top of the high-top sneaker.
    public var shoeTop: Double
    public var sole: Double

    // MARK: - Head

    public var headWidth: Double
    /// 0 = a rounded jaw with no chin, 1 = a sharp wedge.
    public var chinTaper: Double
    /// 0 = a flat-topped cap, 1 = a fully domed cranium.
    public var skullRound: Double
    public var neckWidth: Double
    /// Height of each horn above where it leaves the hair.
    public var hornHeight: Double
    /// Distance between the two horn bases.
    public var hornGap: Double

    // MARK: - Eyes

    /// Eye height as a fraction of face height. She is shown at 60 to 90pt, so
    /// this sits above an adult's ~0.20 on purpose: the cross pupils have to read.
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
    /// How far down the forehead the fringe's points reach, as a fraction of the
    /// gap between crown and brow.
    public var fringeDepth: Double
    /// Width of each long back hair mass where it leaves the head.
    public var tailRootWidth: Double
    /// Width of each back hair mass at its widest, around the shoulders.
    public var tailWidth: Double
    /// Width where the lower half of the mass ends in its points.
    public var tailTipWidth: Double
    /// How far the hair flares out past the head before it falls.
    public var tailFlare: Double
    /// Where each mass hands off from base to tip (the follow-through joint).
    public var tailHandoff: Double
    /// Where the longest point of the hair ends, past her waist.
    public var tailEnd: Double
    /// 0 = falls straight, 1 = the ends kick outward.
    public var tailCurl: Double
    /// Width of the long front locks that fall over her shoulders.
    public var sideLockWidth: Double
    public var sideLockEnd: Double

    // MARK: - Body

    /// Widest point of the ribcage.
    public var ribWidth: Double
    public var waistWidth: Double
    public var hipWidth: Double
    /// Width across the top of the torso, before the arms add their deltoids.
    public var torsoTopWidth: Double
    /// How far the deltoid pushes past the torso on each side.
    public var deltoid: Double
    public var upperArmWidth: Double
    public var foreArmWidth: Double
    /// Width of the loose jacket sleeve hanging over the forearm.
    public var sleeveWidth: Double
    public var thighWidth: Double
    /// Width of the slacks leg at the knee and down to the cuff.
    public var calfWidth: Double
    public var shoeWidth: Double

    // MARK: - Outfit

    /// Where the open jacket's front panels end, below the hips.
    public var jacketHem: Double
    /// Number of fold lines across the rolled trouser cuff. The name is a holdover
    /// from the skirt this rig used to wear; RigStudio's proportion sheet sweeps it.
    public var pleats: Int

    // MARK: - Derived

    public var faceHeight: Double { chin - crown }
    public var shoulderSpan: Double { torsoTopWidth + deltoid * 2 }
    public var eyeLine: Double { crown + faceHeight * 0.53 }
    public var eyeHeight: Double { faceHeight * eyeHeightRatio }
    public var eyeWidth: Double { eyeHeight * eyeAspect }
    public var browLine: Double { eyeLine - eyeHeight * 0.82 }
    public var mouthLine: Double { crown + faceHeight * 0.83 }

    /// The shipped figure: ~5.3 heads crown to sole, shoulders 1.3 head-widths,
    /// long slim legs. The head is biased large so the face reads at 70pt.
    public static let standard = AnimeGirlProportions(
        crown: 27, chin: 70,
        shoulder: 77, elbow: 108, wrist: 133,
        waist: 116, hip: 133, knee: 182, cuff: 208, shoeTop: 222, sole: 239,

        headWidth: 34, chinTaper: 0.95, skullRound: 1.0, neckWidth: 9.0,
        hornHeight: 10, hornGap: 18,

        eyeHeightRatio: 0.235, eyeAspect: 1.22, eyeGap: 5.2,
        irisFill: 0.94, lidWeight: 2.4,

        hairVolume: 5.0, fringeDepth: 0.95,
        tailRootWidth: 10, tailWidth: 18, tailTipWidth: 26,
        tailFlare: 12, tailHandoff: 100, tailEnd: 156, tailCurl: 0.45,
        sideLockWidth: 6.0, sideLockEnd: 100,

        ribWidth: 32, waistWidth: 25, hipWidth: 33, torsoTopWidth: 29,
        deltoid: 7, upperArmWidth: 7.2, foreArmWidth: 6.8, sleeveWidth: 10.5,
        thighWidth: 12, calfWidth: 10, shoeWidth: 10.5,

        jacketHem: 146, pleats: 2
    )
}
