// Place any global data in this file.
// You can import this data from anywhere in your site by using the `import` keyword.

interface SocialLink {
  href: string;
  label: string;
}

interface Site {
  website: string;
  author: string;
  authorFullName: string;
  profile: string;
  desc: string;
  title: string;
  ogImage: string;
  lightAndDarkMode: boolean;
  postPerIndex: number;
  postPerPage: number;
  scheduledPostMargin: number;
  showArchives: boolean;
  showBackButton: boolean;
  editPost: {
    enabled: boolean;
    text: string;
    url: string;
  };
  dynamicOgImage: boolean;
  lang: string;
  timezone: string;
}

// Site configuration
export const SITE: Site = {
  website: "https://justcarlson.com/",
  author: "Justin Carlson",
  authorFullName: "Justin Carlson",
  profile: "https://justcarlson.com/about",
  desc: "Writing about things I find interesting.",
  title: "Justin Carlson",
  ogImage: "og.png",
  lightAndDarkMode: true,
  postPerIndex: 10,
  postPerPage: 10,
  scheduledPostMargin: 15 * 60 * 1000,
  showArchives: false,
  showBackButton: false,
  editPost: {
    enabled: true,
    text: "Edit on GitHub",
    url: "https://github.com/justcarlson/justcarlson.com/edit/main/",
  },
  dynamicOgImage: true,
  lang: "en",
  timezone: "America/Los_Angeles",
};

export const SITE_TITLE = SITE.title;
export const SITE_DESCRIPTION = SITE.desc;

// Navigation links
export const NAV_LINKS: SocialLink[] = [
  {
    href: "/",
    label: "Blog",
  },
  {
    href: "/about",
    label: "About",
  },
];

// Social media links
export const SOCIAL_LINKS: SocialLink[] = [
  {
    href: "https://github.com/justcarlson",
    label: "GitHub",
  },
  {
    href: "https://x.com/_justcarlson",
    label: "X",
  },
  {
    href: "https://www.linkedin.com/in/justincarlson0/",
    label: "LinkedIn",
  },
  {
    href: "/rss.xml",
    label: "RSS",
  },
];

// Icon map for social media
export const ICON_MAP: Record<string, string> = {
  GitHub: "github",
  X: "twitter",
  LinkedIn: "linkedin",
  RSS: "rss",
};

// Newsletter configuration
export const NEWSLETTER_CONFIG = {
  enabled: false,
  provider: "", // Set when newsletter service is configured (e.g., "buttondown", "convertkit")
  formAction: "", // Newsletter provider form action URL
  tag: "", // Optional tag for subscriber segmentation
};

// Social media links for footer/sidebar (with icon and active state)
export const SOCIALS = [
  {
    name: "Github",
    href: "https://github.com/justcarlson",
    linkTitle: `${SITE.authorFullName} on Github`,
    icon: "github",
    active: true,
  },
  {
    name: "X",
    href: "https://x.com/_justcarlson",
    linkTitle: `${SITE.authorFullName} on X`,
    icon: "twitter",
    active: true,
  },
  {
    name: "LinkedIn",
    href: "https://www.linkedin.com/in/justincarlson0/",
    linkTitle: `${SITE.authorFullName} on LinkedIn`,
    icon: "linkedin",
    active: true,
  },
] as const;

// Share links for post sharing
export const SHARE_LINKS = [
  {
    name: "X",
    href: "https://x.com/intent/post?url=",
    linkTitle: `Share this post on X`,
    icon: "twitter",
  },
  {
    name: "BlueSky",
    href: "https://bsky.app/intent/compose?text=",
    linkTitle: `Share this post on BlueSky`,
    icon: "bluesky",
  },
  {
    name: "LinkedIn",
    href: "https://www.linkedin.com/sharing/share-offsite/?url=",
    linkTitle: `Share this post on LinkedIn`,
    icon: "linkedin",
  },
  {
    name: "WhatsApp",
    href: "https://wa.me/?text=",
    linkTitle: `Share this post via WhatsApp`,
    icon: "whatsapp",
  },
  {
    name: "Facebook",
    href: "https://www.facebook.com/sharer.php?u=",
    linkTitle: `Share this post on Facebook`,
    icon: "facebook",
  },
  {
    name: "Telegram",
    href: "https://t.me/share/url?url=",
    linkTitle: `Share this post via Telegram`,
    icon: "telegram",
  },
  {
    name: "Pinterest",
    href: "https://pinterest.com/pin/create/button/?url=",
    linkTitle: `Share this post on Pinterest`,
    icon: "pinterest",
  },
  {
    name: "Mail",
    href: "mailto:?subject=See%20this%20post&body=",
    linkTitle: `Share this post via email`,
    icon: "mail",
  },
] as const;
