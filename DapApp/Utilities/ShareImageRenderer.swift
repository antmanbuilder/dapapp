import UIKit

enum ShareImageRenderer {
    static func renderCard(result: DapResult, username: String, streak: Int) -> UIImage? {
        let width: CGFloat = 1170
        let height: CGFloat = 2079
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))

        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: width, height: height)

            // Background: solid tier color
            let bgColor = result.tier.uiColor
            bgColor.setFill()
            ctx.fill(rect)

            // Dark overlay on top half for depth
            UIColor.black.withAlphaComponent(0.15).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height / 2))

            // Emoji
            let emojiFont = UIFont.systemFont(ofSize: 180)
            let emoji = NSAttributedString(
                string: result.tier.emoji,
                attributes: [.font: emojiFont]
            )
            let emojiSize = emoji.size()
            emoji.draw(at: CGPoint(x: (width - emojiSize.width) / 2, y: 160))

            // dB number — massive
            let dbText = String(format: "%.1f", result.peakDecibels)
            let dbFont = UIFont.systemFont(ofSize: 220, weight: .black)
            let dbAttr = NSAttributedString(
                string: dbText,
                attributes: [.font: dbFont, .foregroundColor: UIColor.white]
            )
            let dbSize = dbAttr.size()
            let dbX = (width - dbSize.width) / 2 - 40
            let dbY: CGFloat = 420
            dbAttr.draw(at: CGPoint(x: dbX, y: dbY))

            // "dB" label
            let dbLabelFont = UIFont.systemFont(ofSize: 72, weight: .bold)
            let dbLabel = NSAttributedString(
                string: "dB",
                attributes: [.font: dbLabelFont, .foregroundColor: UIColor.white.withAlphaComponent(0.6)]
            )
            dbLabel.draw(at: CGPoint(x: dbX + dbSize.width + 8, y: dbY + 100))

            // Tier title
            let titleFont = UIFont.systemFont(ofSize: 54, weight: .heavy)
            let title = NSAttributedString(
                string: result.tier.displayTitle,
                attributes: [.font: titleFont, .foregroundColor: UIColor.white.withAlphaComponent(0.9)]
            )
            let titleSize = title.size()
            title.draw(at: CGPoint(x: (width - titleSize.width) / 2, y: 740))

            // Divider lines around title
            let lineY = 740 + titleSize.height / 2
            UIColor.white.withAlphaComponent(0.3).setFill()
            ctx.fill(CGRect(x: 60, y: lineY, width: (width - titleSize.width) / 2 - 80, height: 3))
            ctx.fill(CGRect(x: (width + titleSize.width) / 2 + 20, y: lineY, width: (width - titleSize.width) / 2 - 80, height: 3))

            // Username + streak
            var userStr = "@\(username)"
            if streak > 0 {
                userStr += "  🔥 \(streak)"
            }
            let userFont = UIFont.systemFont(ofSize: 42, weight: .bold)
            let userAttr = NSAttributedString(
                string: userStr,
                attributes: [.font: userFont, .foregroundColor: UIColor.white.withAlphaComponent(0.75)]
            )
            let userSize = userAttr.size()
            userAttr.draw(at: CGPoint(x: (width - userSize.width) / 2, y: 850))

            // CTA box at bottom
            let ctaRect = CGRect(x: 60, y: height - 340, width: width - 120, height: 200)
            UIColor.white.withAlphaComponent(0.15).setFill()
            let ctaPath = UIBezierPath(roundedRect: ctaRect, cornerRadius: 36)
            ctaPath.fill()

            let ctaFont = UIFont.systemFont(ofSize: 46, weight: .heavy)
            let ctaText = NSAttributedString(
                string: "think you can beat me? 👀",
                attributes: [.font: ctaFont, .foregroundColor: UIColor.white]
            )
            let ctaSize = ctaText.size()
            ctaText.draw(at: CGPoint(
                x: (width - ctaSize.width) / 2,
                y: ctaRect.midY - ctaSize.height - 5
            ))

            let brandFont = UIFont.systemFont(ofSize: 30, weight: .bold)
            let brandText = NSAttributedString(
                string: "D A P   A P P",
                attributes: [.font: brandFont, .foregroundColor: UIColor.white.withAlphaComponent(0.4)]
            )
            let brandSize = brandText.size()
            brandText.draw(at: CGPoint(
                x: (width - brandSize.width) / 2,
                y: ctaRect.midY + 10
            ))
        }
    }
}
