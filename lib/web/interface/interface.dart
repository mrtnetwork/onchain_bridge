import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/interface/interface.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/web/types/file.dart';
import 'package:on_chain_bridge/web/web.dart';

abstract class IWebOnChainBridgeInterface<
        CREDENTIALRESPONSE extends PlatformCredentialResponse,
        CREDENTIALAUTHREQUEST extends PlatformCredentialAutneticateRequest>
    implements
        IOnChainBridgeInterface<PlatformCredentialWebResponse,
            PlatformCredentialAutneticateWebRequest, WebFile> {
  Result<Window, IException> window();
  Result<ChromeAPI, IException> chromeApi();
  // Future<Result<bool, IException>> shareFile(Share share, JSFile file);
  bool get isExtensionContext;
}
