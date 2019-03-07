module Gitlab
  module Insights
    COLOR_SCHEME = {
      red: '#e6194B',
      green: '#3cb44b',
      yellow: '#ffe119',
      blue: '#4363d8',
      orange: '#f58231',
      purple: '#911eb4',
      cyan: '#42d4f4',
      magenta: '#f032e6',
      lime: '#bfef45',
      pink: '#fabebe',
      teal: '#469990',
      lavender: '#e6beff',
      brown: '#9A6324',
      beige: '#fffac8',
      maroon: '#800000',
      mint: '#aaffc3',
      olive: '#808000',
      apricot: '#ffd8b1'
    }

    UNCATEGORIZED = 'undefined'
    UNCATEGORIZED_COLOR = "#808080"
    TOP_COLOR = "#FF0000"
    HIGH_COLOR = "#ff8800"
    MEDIUM_COLOR = "#fff600"
    LOW_COLOR = "#008000"
    PROPOSAL_COLOR = "#f0ad4e"
    BUG_COLOR = "#ff0000"
    SECURITY_COLOR = "#d9534f"
    COMMUNITY_CONTRIBUTION_COLOR = "#a8d695"
    DEFAULT_COLOR = "#428bca"
    LINE_COLOR = COLOR_SCHEME[:red]

    STATIC_COLOR_MAP = {
      UNCATEGORIZED => UNCATEGORIZED_COLOR,
      "S1" => TOP_COLOR,
      "S2" => HIGH_COLOR,
      "S3" => MEDIUM_COLOR,
      "S4" => LOW_COLOR,
      "P1" => TOP_COLOR,
      "P2" => HIGH_COLOR,
      "P3" => MEDIUM_COLOR,
      "P4" => LOW_COLOR,
      "feature" => PROPOSAL_COLOR,
      "bug" => BUG_COLOR,
      "security" => SECURITY_COLOR,
      "Community contribution" => COMMUNITY_CONTRIBUTION_COLOR,
      "backstage" => DEFAULT_COLOR,
      "Manage" => COLOR_SCHEME[:orange],
      "Plan" => COLOR_SCHEME[:green],
      "Create" => COLOR_SCHEME[:yellow],
      "Package" => COLOR_SCHEME[:purple],
      "Serverless" => COLOR_SCHEME[:olive],
      "Release" => COLOR_SCHEME[:beige],
      "Verify" => COLOR_SCHEME[:blue],
      "Configure" => COLOR_SCHEME[:cyan],
      "Monitor" => COLOR_SCHEME[:magenta],
      "Secure" => COLOR_SCHEME[:lime],
      "Distribution" => COLOR_SCHEME[:pink],
      "Gitaly" => COLOR_SCHEME[:teal],
      "Geo" => COLOR_SCHEME[:lavender],
      "Quality" => COLOR_SCHEME[:maroon],
      "gitter" => COLOR_SCHEME[:brown],
      "frontend" => COLOR_SCHEME[:mint]
    }
  end
end
