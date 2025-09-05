import 'dart:js_interop';
import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/web/api/window/window.dart';

class _WebAuthConstants {
  static const String pkType = "public-key";
  static const int p256AlgId = -7;
}

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
@JS("PublicKeyCredential")
extension type PublicKeyCredential<T extends AuthenticatorResponse>._(
    JSObject _) implements Credential {
  external static JSPromise<JSBoolean>
      isUserVerifyingPlatformAuthenticatorAvailable();
  external static JSPromise<JSAny> signalAllAcceptedCredentials();
  external JSArrayBuffer get rawId;
  external T response;
  static Future<bool> isUserVerifyingPlatformAuthenticatorAvailable_() async {
    try {
      final available =
          await isUserVerifyingPlatformAuthenticatorAvailable().toDart;
      return available.toDart;
    } catch (e) {
      return false;
    }
  }
}

extension type AuthenticatorResponse._(JSObject _) implements JSAny {
  external JSArrayBuffer get clientDataJSON;
}
extension type AuthenticatorResponseGet._(JSObject _)
    implements AuthenticatorResponse {
  external JSArrayBuffer get authenticatorData;
  external JSArrayBuffer get signature;
  external JSArrayBuffer get userHandle;
}
extension type AuthenticatorResponseCreate._(JSObject _)
    implements AuthenticatorResponse {
  external JSArrayBuffer get attestationObject;
  external JSArrayBuffer getAuthenticatorData();
  external JSArrayBuffer getPublicKey();
  external JSNumber getPublicKeyAlgorithm();
  external JSArray<JSString> getTransports();
}
@JS("CredentialsContainer")
extension type CredentialsContainer._(JSObject _) implements JSAny {
  external JSPromise<PublicKeyCredential<AuthenticatorResponseCreate>> create(
      CreateCredentialsParams? params);
  external JSPromise<PublicKeyCredential<AuthenticatorResponseGet>> get(
      GetCredentialsParams? params);
  Future<PublicKeyCredential<AuthenticatorResponseCreate>?> create_(
      {required String rpName,
      required String name,
      required String displayName,
      required List<int> id,
      String? rpId}) async {
    rpId ??= jsWindow.location.hostName;
    final auth = await create(
      CreateCredentialsParams(
        publicKey: PublicKeyCredentialCreationOptions(
            rp: RP(id: rpId.toJS, name: rpName.toJS),
            user: User(
                displayName: displayName.toJS,
                id: Uint8List.fromList(id).toJS,
                name: name.toJS),
            authenticatorSelection: Authenticatorselection(
              authenticatorAttachment:
                  Authenticatorattachment.platform.name.toJS,
            ),
            challenge: Uint8List.fromList(QuickCrypto.generateRandom()).toJS,
            pubKeyCredParams: [
              PubKeyCredParams(
                  type: _WebAuthConstants.pkType.toJS,
                  alg: _WebAuthConstants.p256AlgId.toJS),
            ].toJS),
      ),
    ).toDart;
    final type = auth.type.toDart;
    final pkAlgorith = auth.response.getPublicKeyAlgorithm().toDartInt;

    if (type == _WebAuthConstants.pkType &&
        pkAlgorith == _WebAuthConstants.p256AlgId) {
      return auth;
    }
    return null;
  }

  Future<PublicKeyCredential<AuthenticatorResponseGet>?> get_(
      {required List<int> id, required List<int> challenge}) async {
    final auth = await jsWindow.navigator.credentials!
        .get(
          GetCredentialsParams(
            mediation: Mediation.required.name.toJS,
            publicKey: PublicKeyCredentialRequestOptions(
              challenge: Uint8List.fromList(challenge).toJS,
              userVerification: Userverification.required.name.toJS,
              allowCredentials: [
                Excludecredentials(
                    id: Uint8List.fromList(id).toJS, type: "public-key".toJS),
              ].toJS,
            ),
          ),
        )
        .toDart;
    final type = auth.type.toDart;
    if (type == _WebAuthConstants.pkType &&
        BytesUtils.bytesEqual(
            id,
            StringUtils.encode(auth.id.toDart,
                validateB64Padding: false,
                type: StringEncoding.base64UrlSafe,
                allowUrlSafe: true))) {
      return auth;
    }

    return null;
  }
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
      JSArray<Excludecredentials>? allowCredentials,
      JSAny? extensions,
      JSArray<JSString>? hints,
      JSString? rpId,
      JSNumber? timeout,
      JSString? userVerification});
}

enum Mediation {
  conditional,
  optional,
  required,
  silent;
}
