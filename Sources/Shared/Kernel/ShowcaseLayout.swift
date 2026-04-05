import CoreGraphics

public enum ShowcaseLayout {
    public enum Space {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 10
        public static let lg: CGFloat = 12
        public static let xl: CGFloat = 16
        public static let xxl: CGFloat = 18
        public static let section: CGFloat = 20
        public static let hero: CGFloat = 24
        public static let screen: CGFloat = 28
        public static let loginVertical: CGFloat = 48
    }

    public enum Inset {
        public static let row: CGFloat = 16
        public static let screenX: CGFloat = 20
        public static let screenXWide: CGFloat = 24
        public static let card: CGFloat = 20
        public static let formBlock: CGFloat = 24
        public static let qrPadding: CGFloat = 18
        public static let listVertical: CGFloat = 12
        public static let bannerVertical: CGFloat = 8
        public static let bannerContent: CGFloat = 16
        public static let loadingLabelX: CGFloat = 20
        public static let loadingLabelTop: CGFloat = 8
        public static let badgeHorizontal: CGFloat = 8
        public static let badgeVertical: CGFloat = 2
    }

    public enum Radius {
        public static let badge: CGFloat = 6
        public static let line: CGFloat = 8
        public static let block: CGFloat = 16
        public static let banner: CGFloat = 18
        public static let row: CGFloat = 20
        public static let qrCutout: CGFloat = 20
        public static let card: CGFloat = 24
        public static let loginCard: CGFloat = 28
        public static let pill: CGFloat = 999
    }

    public enum Line {
        public static let stroke: CGFloat = 1
    }

    public enum ContentWidth {
        public static let login: CGFloat = 560
        public static let detail: CGFloat = 640
    }

    public enum QR {
        public static let side: CGFloat = 220
    }

    public enum Skeleton {
        public enum ListRow {
            public static let primaryLineWidth: CGFloat = 78
            public static let primaryLineHeight: CGFloat = 16
            public static let secondaryLineWidth: CGFloat = 120
            public static let secondaryLineHeight: CGFloat = 12
            public static let trailingShortWidth: CGFloat = 48
            public static let trailingShortHeight: CGFloat = 14
            public static let pillWidth: CGFloat = 72
            public static let pillHeight: CGFloat = 22
        }

        public enum Detail {
            public static let titleWidth: CGFloat = 110
            public static let titleHeight: CGFloat = 28
            public static let subtitleWidth: CGFloat = 180
            public static let subtitleHeight: CGFloat = 18
            public static let rowLineHeight: CGFloat = 20
            public static let weatherBlockHeight: CGFloat = 92
            public static let weatherLine1Width: CGFloat = 140
            public static let weatherLine1Height: CGFloat = 18
            public static let weatherLine2Width: CGFloat = 180
            public static let weatherLine2Height: CGFloat = 16
            public static let actionPlaceholderHeight: CGFloat = 52
        }

        public enum BoardingPass {
            public static let headerBlockHeight: CGFloat = 104
            public static let qrBlockHeight: CGFloat = 278
            public static let detailsBlockHeight: CGFloat = 144
        }

        public enum List {
            public static let paginationSpacer: CGFloat = 1
        }

        public enum Shimmer {
            public static let highlightWidthRatio: CGFloat = 0.35
            public static let minHighlightWidth: CGFloat = 80
            public static let cycleDuration: Double = 1.25
            public static let rotationDegrees: CGFloat = 18
            public static let offsetPhaseMultiplier: CGFloat = 1.8
            public static let offsetBaseMultiplier: CGFloat = 0.7
        }
    }
}
