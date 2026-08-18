import CoreGraphics
import Testing
@testable import Pomodoro

/// The pill's arithmetic.
///
/// Worth a suite of its own because every failure here is silent. The row is laid out
/// at full width in both forms and *revealed* by a narrowing box, so nothing throws and
/// nothing looks broken in isolation — the collapsed pill simply cuts through the play
/// button, or leaves a strip of glass where the skip button used to be, or the box no
/// longer matches the rect AppKit hit-tests against and clicks land nowhere. All three
/// need a running timer and a real cursor to notice, and all three are one arithmetic
/// slip away at any time.
///
/// Every comparison goes through `Double` rather than comparing the `CGFloat`s directly,
/// and that is not decoration. `#expect(a == b)` on two `CGFloat`s fails on this
/// toolchain even when the values are bit-identical — it reports
/// `(a → 134.0) == (b → 134.0)` as a failure, because CGFloat's implicit conversion to
/// Double makes the macro pick an overload that does not compare what it prints. A
/// suite that is wrong in the failing direction is survivable; one that is wrong in the
/// passing direction would not be, so the conversion stays.
@Suite("Bar geometry")
@MainActor
struct BarGeometryTests {

    private typealias M = FloatingBar.Metrics

    /// The row must consume the frame exactly.
    ///
    /// Any slack at all and the layout distributes it, which makes every control's
    /// position depend on the box width instead of being fixed by it — and then the
    /// contents shift during a morph, which is the one thing this arrangement exists to
    /// prevent.
    @Test("The control row adds up to the pill's width with nothing left over")
    func rowFillsTheFrame() {
        let row = M.leading
            + M.ring + M.ringGap
            + M.readout + M.readoutGap
            + M.primary + M.controlGap
            + M.secondary + M.controlGap
            + M.secondary
            + M.trailing

        #expect(Double(row) == Double(M.width))
        #expect(Double(FloatingBar.size.width) == Double(M.width))
    }

    /// The reason the compact form is 172pt and not the 133 it used to be.
    @Test("The collapsed pill contains the whole play button, plus its trailing air")
    func compactClearsThePrimaryControl() {
        let primaryTrailingEdge = M.primaryX + M.primary

        #expect(M.compactWidth > primaryTrailingEdge)
        #expect(Double(M.compactWidth - primaryTrailingEdge) == Double(M.trailing))
        #expect(Double(FloatingBar.compactSize.width) == Double(M.compactWidth))
    }

    /// A secondary control is parked *under* the play button, not merely near it —
    /// which is the whole basis of it reading as emerging from underneath.
    @Test("Each secondary control tucks to the play button's leading edge")
    func secondariesParkUnderThePrimary() {
        for index in 0..<2 {
            #expect(Double(M.secondaryX(index) + M.tuck(index)) == Double(M.primaryX))
        }
    }

    /// Parked, they have to be inside the play button or they show through the clip.
    @Test("A parked secondary control sits inside the play button, so the clip hides it")
    func parkedSecondariesAreCovered() {
        for index in 0..<2 {
            let parked = M.secondaryX(index) + M.tuck(index)
            #expect(parked >= M.primaryX)
            #expect(parked + M.secondary <= M.primaryX + M.primary)
        }
    }

    /// Both forms share a leading edge; only the trailing edge travels.
    @Test("The two forms share their leading edge and their vertical centre")
    func formsShareTheirLeadingEdge() {
        #expect(Double(FloatingBar.compactFrame.minX) == Double(FloatingBar.pillFrame.minX))
        #expect(Double(FloatingBar.compactFrame.midY) == Double(FloatingBar.pillFrame.midY))
        #expect(FloatingBar.compactFrame.width < FloatingBar.pillFrame.width)
    }

    /// The offset that holds the leading edge still while the box narrows about its own
    /// centre. Wrong sign or wrong factor and the pill drifts sideways across a morph,
    /// which is precisely the defect the leading anchor exists to remove.
    @Test("The box's offset lands both forms on the same leading edge")
    func offsetHoldsTheLeadingEdge() {
        for width in [M.compactWidth, M.width] {
            // `FloatingBarView.pill`: the box is centred at the expanded pill's midpoint
            // and then shifted by this.
            let offset = (width - M.width) / 2
            let centre = FloatingBar.pillFrame.midX + offset
            #expect(Double(centre - width / 2) == Double(FloatingBar.pillFrame.minX))
        }
    }

    /// The hit rect narrows on a delay, and the delay has to outlast the animation or
    /// a click during the collapse lands in the gap between them.
    @Test("The hit-rect delay outlasts the morph it is waiting for")
    func morphDurationCoversTheSpring() {
        // `.smooth(duration: 0.42)` in `FloatingBarView.morph`. A spring has no exact
        // end, so the rule is only that this errs long: the target staying large a
        // moment past the animation costs nothing, the reverse drops clicks.
        #expect(FloatingBar.morphDuration > 0.42)
    }
}
