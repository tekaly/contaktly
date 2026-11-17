import 'package:contaktly_form/contaktly_form.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// What a form shows of its owner: a name, a photo, an image on top.
class ContaktlyFormProfile {
  /// The display name.
  final String name;

  /// The photo, none when null.
  final String? photoUrl;

  /// The image on top, none when null.
  final String? imageUrl;

  /// A profile.
  const ContaktlyFormProfile({
    required this.name,
    this.photoUrl,
    this.imageUrl,
  });

  /// The profile of a user form, null for the others.
  static ContaktlyFormProfile? of(ContaktlyFormMixin form) {
    var profile = form.profile.v;
    if (profile == null) {
      return null;
    }
    return ContaktlyFormProfile(
      name: profile.name.v ?? '',
      photoUrl: profile.pictureUrl.v,
      imageUrl: profile.imageUrl.v,
    );
  }
}

/// The image and the owner of a form, above it: [profile]'s image, its
/// photo and name (the title already says the name when there is no
/// photo).
List<Component> contaktlyFormProfileHeader(ContaktlyFormProfile? profile) => [
  if (profile?.imageUrl case var imageUrl?)
    img(
      classes: 'cf-cover',
      src: imageUrl,
      alt: '',
      attributes: const {'referrerpolicy': 'no-referrer'},
    ),
  if (profile?.photoUrl case var photoUrl?)
    div(classes: 'cf-profile', [
      img(
        src: photoUrl,
        alt: '',
        width: 56,
        height: 56,
        attributes: const {'referrerpolicy': 'no-referrer'},
      ),
      span(classes: 'cf-profile-name', [.text(profile!.name)]),
    ]),
];
