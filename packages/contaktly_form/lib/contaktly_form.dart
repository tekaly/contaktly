/// Contaktly contact forms, pure Dart (no `dart:io`): the model of a
/// published form, its texts, validation, the controller of a form for any
/// UI, the senders of a message (the contaktly backend, a simulation, a
/// function of yours) and the loading of a published form from its forms
/// site.
///
/// Each export lists what it exports: a declaration added to `lib/src`
/// stays internal until it is listed here.
library;

export 'src/contaktly_constants.dart'
    show
        contaktlyAppDev,
        contaktlyAppProd,
        contaktlyCommandUrlDart,
        contaktlyCommandUrlDartDev,
        contaktlyCommandUrlDartProd,
        contaktlyFormDefaultEncPaths,
        contaktlyFormIdPath,
        contaktlyIsValidFormId,
        contaktlySignedPaths;
export 'src/form_controller.dart'
    show ContaktlyFormController, ContaktlyFormStatus;
export 'src/form_embed.dart'
    show
        contaktlyFormIframeAttribute,
        contaktlyFormJsonUrl,
        contaktlyFormMessageHeight,
        contaktlyFormMessageSent,
        contaktlyFormPageUrl,
        contaktlyFormPublishedLoad;
export 'src/form_files.dart'
    show
        ContaktlyFormFile,
        CvContaktlyFormAttachments,
        CvContaktlyFormSendFile,
        contaktlyFormFileAccept,
        contaktlyFormFileExtensions,
        contaktlyFormFileMaxSize,
        contaktlyFormFileTypeOf,
        contaktlyFormFileTypes,
        contaktlyFormFilesKey,
        contaktlyFormFilesMaxSize;
export 'src/form_message.dart'
    show
        ContaktlyFormValues,
        contaktlyFormIsLikelySpam,
        contaktlyFormMailMessage,
        contaktlyFormMinFillDuration,
        contaktlyFormValidate;
export 'src/form_model.dart'
    show
        ContaktlyFormMixin,
        ContaktlyFormMixinExt,
        CvContaktlyForm,
        CvContaktlyFormField,
        CvContaktlyFormLook,
        CvContaktlyFormProfile,
        CvContaktlyFormPublished,
        CvContaktlyFormTexts,
        contaktlyFormBrightnessDark,
        contaktlyFormBrightnessLight,
        contaktlyFormBrightnessSystem,
        contaktlyFormFieldEmail,
        contaktlyFormFieldKeys,
        contaktlyFormFieldMessage,
        contaktlyFormFieldName,
        contaktlyFormFieldSubject,
        initContaktlyFormBuilders;
export 'src/form_sender.dart'
    show
        ContaktlyFormSendException,
        ContaktlyFormSendResult,
        ContaktlyFormSender,
        ContaktlyFormSimulation,
        ContaktlyFunctionSender,
        ContaktlySimulatedSender,
        contaktlyFormErrorClosed,
        contaktlyFormErrorCodeClosed,
        contaktlyFormSendErrorText,
        contaktlyFormSimulatedSend,
        contaktlyFormSimulationDelay,
        contaktlyFormSimulationParse,
        contaktlyMailStatusTrial;
export 'src/form_texts.dart'
    show
        ContaktlyFormStrings,
        contaktlyFormDefaultStrings,
        contaktlyFormStrings,
        contaktlyFormStringsEn,
        contaktlyFormStringsFr;
export 'src/service_sender.dart'
    show ContaktlyFormSendQuery, ContaktlyServiceSender;
