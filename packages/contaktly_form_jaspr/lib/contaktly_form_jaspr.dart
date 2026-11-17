/// A contaktly contact form for jaspr sites: [ContaktlyContactForm] for a
/// published form in a page (its css scoped, its island), the island
/// [ContaktlyFormIsland] sending through the contaktly backend, and
/// [ContaktlyContactFormView] for an island of your own with another
/// sender. The loader of a form published on its forms site is server only:
/// `package:contaktly_form_jaspr/server.dart`.
///
/// Each export lists what it exports: a declaration added to `lib/src`
/// stays internal until it is listed here.
library;

export 'package:contaktly_form/contaktly_form.dart'
    show
        ContaktlyFormMixin,
        ContaktlyFormSendResult,
        ContaktlyFormSender,
        ContaktlyFormSimulation,
        ContaktlyFormStrings,
        ContaktlyFunctionSender,
        ContaktlyServiceSender,
        ContaktlySimulatedSender,
        CvContaktlyForm,
        CvContaktlyFormPublished,
        contaktlyFormJsonUrl,
        contaktlyFormPublishedLoad;

export 'src/contact_form.dart'
    show ContaktlyContactForm, contaktlyFormRootClass;
export 'src/form_island.dart' show ContaktlyFormIsland;
export 'src/form_profile.dart'
    show ContaktlyFormProfile, contaktlyFormProfileHeader;
export 'src/form_style.dart' show contaktlyFormCss;
export 'src/form_view.dart'
    show ContaktlyContactFormView, contaktlyFormHoneypotName;
