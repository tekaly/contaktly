/// A contaktly contact form as a Flutter widget: [ContaktlyContactForm] for
/// a form and its sender, [ContaktlyPublishedForm] for a form published on
/// its forms site.
///
/// Each export lists what it exports: a declaration added to `lib/src`
/// stays internal until it is listed here.
library;

export 'package:contaktly_form/contaktly_form.dart'
    show
        ContaktlyFormController,
        ContaktlyFormMixin,
        ContaktlyFormSendResult,
        ContaktlyFormSender,
        ContaktlyFormSimulation,
        ContaktlyFormStatus,
        ContaktlyFormStrings,
        ContaktlyFunctionSender,
        ContaktlyServiceSender,
        ContaktlySimulatedSender,
        CvContaktlyForm,
        CvContaktlyFormProfile,
        CvContaktlyFormPublished,
        contaktlyFormPublishedLoad;

export 'src/contaktly_contact_form.dart'
    show
        ContaktlyContactForm,
        ContaktlyContactFormProfile,
        contaktlyContactFormAnotherKey,
        contaktlyContactFormFieldKey,
        contaktlyContactFormProfileKey,
        contaktlyContactFormSubmitKey;
export 'src/contaktly_published_form.dart' show ContaktlyPublishedForm;
