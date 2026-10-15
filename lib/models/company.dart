class Company {
  final String name;
  final String industry;
  final String description;
  final String website;
  final String instagram;
  final String telegram;
  final String vk;

  const Company({
    this.name = '',
    this.industry = '',
    this.description = '',
    this.website = '',
    this.instagram = '',
    this.telegram = '',
    this.vk = '',
  });

  factory Company.fromMap(Map<String, dynamic> m) => Company(
        name: (m['name'] ?? '') as String,
        industry: (m['industry'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        website: (m['website'] ?? '') as String,
        instagram: (m['instagram'] ?? '') as String,
        telegram: (m['telegram'] ?? '') as String,
        vk: (m['vk'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'industry': industry,
        'description': description,
        'website': website,
        'instagram': instagram,
        'telegram': telegram,
        'vk': vk,
      };
}
