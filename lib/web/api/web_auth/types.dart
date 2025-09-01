import 'dart:js_interop';

enum Attestation { none, direct, enterprise, indirect }

extension type PublicKeyCredentialCreationOptions._(JSObject _)
    implements JSAny {
  external factory PublicKeyCredentialCreationOptions(
      {JSString? attestation,
      JSArray<JSString>? attestationFormats,
      Authenticatorselection? authenticatorSelection,
      JSUint8Array challenge,
      JSArray<Excludecredentials>? excludeCredentials,
      JSAny? extensions,
      JSArray<JSString>? hints,
      JSArray<PubKeyCredParams>? pubKeyCredParams,
      RP? rp,
      JSNumber? timeout,
      User? user});
}

extension type Authenticatorselection._(JSObject _) implements JSAny {
  external factory Authenticatorselection({
    JSString? authenticatorAttachment,
    JSString? requireResidentKey,
    JSString? residentKey,
    JSString? userVerification,
  });
}

enum Authenticatorattachment {
  platform("platform"),
  crossPlatform("cross-platform");

  const Authenticatorattachment(this.name);
  final String name;
}

enum Residentkey {
  discouraged,
  preferred,
  required;
}

enum Userverification {
  discouraged,
  preferred,
  required;
}

extension type Excludecredentials._(JSObject _) implements JSAny {
  external factory Excludecredentials(
      {JSUint8Array id, JSArray<JSString>? transports, JSString? type});
}

extension type PubKeyCredParams._(JSObject _) implements JSAny {
  external factory PubKeyCredParams({JSString type, JSNumber? alg});
}
extension type RP._(JSObject _) implements JSAny {
  external factory RP({JSString? id, JSString name});
}

extension type User._(JSObject _) implements JSAny {
  external factory User({JSUint8Array id, JSString displayName, JSString name});
}
extension type Credential._(JSObject _) implements JSAny {
  external JSString get id;
  external JSString get type;
}
extension type PublicKeyCredential._(JSObject _) implements Credential {
  // external Authenticatorattachment get authenticatorAttachment;
  external JSArrayBuffer get rawId;
  external JSAny? response;
}
@JS("CredentialsContainer")
extension type CredentialsContainer._(JSObject _) implements JSAny {
  external JSPromise<PublicKeyCredential> create(
      CreateCredentialsParams? params);
  external JSPromise<PublicKeyCredential> get(GetCredentialsParams? params);
}
extension type CreateCredentialsParams._(JSObject _) implements JSAny {
  external factory CreateCredentialsParams(
      {PublicKeyCredentialCreationOptions publicKey, JSAny? signal});
}
extension type GetCredentialsParams._(JSObject _) implements JSAny {
  external factory GetCredentialsParams(
      {PublicKeyCredentialRequestOptions publicKey,
      JSAny? signal,
      JSString? mediation});
}

extension type PublicKeyCredentialRequestOptions._(JSObject _)
    implements JSAny {
  external factory PublicKeyCredentialRequestOptions(
      {JSUint8Array challenge,
      JSArray<Excludecredentials>? allowcredentials,
      JSAny? extensions,
      JSArray<JSString>? hints,
      JSString? rpId,
      JSNumber? timeout,
      JSString? userverification});
}

enum Mediation {
  conditional,
  optional,
  required,
  silent;
}
