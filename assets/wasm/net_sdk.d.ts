/* tslint:disable */
/* eslint-disable */
/**
 * The `ReadableStreamType` enum.
 *
 * *This API requires the following crate features to be activated: `ReadableStreamType`*
 */

type ReadableStreamType = "bytes";

export class DartTransporter {
    free(): void;
    [Symbol.dispose](): void;
    close_all_transports(): Promise<NetResultStatus>;
    close_transport(transport_id: number): Promise<NetResultStatus>;
    static create(callback: Function): DartTransporter;
    create_transporter(config: NetConfigRequestWasm): number;
    constructor(callback: Function);
    send_request(request: NetRequestWasm): Promise<NetResponseWasm>;
    version(): number;
}

export class IntoUnderlyingByteSource {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    cancel(): void;
    pull(controller: ReadableByteStreamController): Promise<any>;
    start(controller: ReadableByteStreamController): void;
    readonly autoAllocateChunkSize: number;
    readonly type: ReadableStreamType;
}

export class IntoUnderlyingSink {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    abort(reason: any): Promise<any>;
    close(): Promise<any>;
    write(chunk: any): Promise<any>;
}

export class IntoUnderlyingSource {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    cancel(): void;
    pull(controller: ReadableStreamDefaultController): Promise<any>;
}

export class NetConfigHttpWasm {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    static create(headers: NetHttpHeader[], streaming: boolean): NetConfigHttpWasm;
}

export class NetConfigRequestWasm {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    static create(url: string, protocol: NetProtocol, http: NetConfigHttpWasm, encoding: StreamEncoding): NetConfigRequestWasm;
}

export class NetHttpHeader {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    static create(key: string, value: string): NetHttpHeader;
    readonly key: string;
    readonly value: string;
}

export class NetHttpRetryConfig {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    static create(max_retries: number, retry_status: Uint16Array, retry_delay: number): NetHttpRetryConfig;
}

export enum NetProtocol {
    Http = 1,
    Grpc = 2,
    WebSocket = 3,
    Socket = 4,
}

export class NetRequestGrpcStream {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    static create(method: string, data: Uint8Array): NetRequestGrpcStream;
}

export class NetRequestGrpcUnary {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    static create(method: string, data: Uint8Array): NetRequestGrpcUnary;
}

export class NetRequestGrpcUnsubscribe {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    static create(id: number): NetRequestGrpcUnsubscribe;
}

export class NetRequestHttp {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    static create(method: string, url: string, body: Uint8Array | null | undefined, headers: NetHttpHeader[] | null | undefined, encoding: StreamEncoding, retry: NetHttpRetryConfig, streaming_id: number): NetRequestHttp;
}

export class NetRequestSocketSend {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    static create(data: Uint8Array): NetRequestSocketSend;
    static from_serde(v: any): NetRequestSocketSend;
}

export class NetRequestWasm {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    static create(transport_id: number, id: number, timeout: number, kind: number, socket_send?: NetRequestSocketSend | null, grpc_unary?: NetRequestGrpcUnary | null, grpc_stream?: NetRequestGrpcStream | null, grpc_unsubscribe?: NetRequestGrpcUnsubscribe | null, http?: NetRequestHttp | null): NetRequestWasm;
    static fromserde(value: any): NetRequestWasm;
}

export class NetResponseGrpcSubscribe {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    /**
     * Getter for `id`
     */
    readonly id: number;
    readonly message: string;
    readonly status: number;
}

export class NetResponseGrpcUnary {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    /**
     * Getter for `data`
     */
    readonly data: Uint8Array;
    readonly message: string;
    readonly status: number;
}

export class NetResponseGrpcUnsubscribe {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    /**
     * Getter for `id`
     */
    readonly id: number;
}

export class NetResponseHttp {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    /**
     * Getter for `body`
     */
    readonly body: Uint8Array;
    /**
     * Getter for `headers`
     */
    readonly headers: NetHttpHeader[];
    /**
     * Getter for `status_code`
     */
    readonly status_code: number;
    /**
     * Getter for `body`
     */
    readonly stream_id: number | undefined;
}

export class NetResponseSocketStatus {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    readonly code: number;
    readonly message: string;
}

export class NetResponseStreamData {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    readonly data: Uint8Array;
    readonly id: number | undefined;
}

export class NetResponseStreamError {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    readonly code: number;
    /**
     * Getter for `status`
     */
    readonly error: NetResultStatus;
    /**
     * Getter for `id`
     */
    readonly id: number | undefined;
    readonly message: string;
}

export class NetResponseWasm {
    private constructor();
    free(): void;
    [Symbol.dispose](): void;
    readonly grpc_stream: NetResponseGrpcSubscribe | undefined;
    readonly grpc_unary: NetResponseGrpcUnary | undefined;
    readonly grpc_unsubscribe: NetResponseGrpcUnsubscribe | undefined;
    readonly http: NetResponseHttp | undefined;
    readonly kind: number;
    readonly request_id: number;
    readonly response_error: NetResultStatus | undefined;
    readonly stream_close: number | undefined;
    readonly stream_data: NetResponseStreamData | undefined;
    readonly stream_error: NetResponseStreamError | undefined;
    readonly transport_id: number;
}

export enum NetResultStatus {
    OK = 100,
    InvalidUrl = 1,
    TlsError = 2,
    ConnectionError = 3,
    TorNetError = 4,
    SocketError = 10,
    Http2ConctionFailed = 13,
    InvalidRequestParameters = 15,
    InvalidConfigParameters = 16,
    TransportNotFound = 17,
    BadHttpRequestHost = 19,
    RequestTimeout = 22,
    InvalidTorConfig = 23,
    TorInitializationFailed = 24,
    TorClientNotInitialized = 26,
    InternalError = 27,
    InstanceDoesNotExist = 28,
}

export enum StreamEncoding {
    Map = 1,
    Raw = 2,
    ListOfMap = 3,
    String = 4,
    Json = 5,
}

export function start(): void;

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
    readonly memory: WebAssembly.Memory;
    readonly __wbg_darttransporter_free: (a: number, b: number) => void;
    readonly __wbg_netconfighttpwasm_free: (a: number, b: number) => void;
    readonly __wbg_netconfigrequestwasm_free: (a: number, b: number) => void;
    readonly __wbg_nethttpheader_free: (a: number, b: number) => void;
    readonly __wbg_nethttpretryconfig_free: (a: number, b: number) => void;
    readonly __wbg_netrequestgrpcstream_free: (a: number, b: number) => void;
    readonly __wbg_netrequestgrpcunsubscribe_free: (a: number, b: number) => void;
    readonly __wbg_netrequesthttp_free: (a: number, b: number) => void;
    readonly __wbg_netrequestsocketsend_free: (a: number, b: number) => void;
    readonly __wbg_netrequestwasm_free: (a: number, b: number) => void;
    readonly __wbg_netresponsegrpcsubscribe_free: (a: number, b: number) => void;
    readonly __wbg_netresponsegrpcunary_free: (a: number, b: number) => void;
    readonly __wbg_netresponsegrpcunsubscribe_free: (a: number, b: number) => void;
    readonly __wbg_netresponsehttp_free: (a: number, b: number) => void;
    readonly __wbg_netresponsesocketstatus_free: (a: number, b: number) => void;
    readonly __wbg_netresponsestreamdata_free: (a: number, b: number) => void;
    readonly __wbg_netresponsestreamerror_free: (a: number, b: number) => void;
    readonly __wbg_netresponsewasm_free: (a: number, b: number) => void;
    readonly darttransporter_close_all_transports: (a: number) => number;
    readonly darttransporter_close_transport: (a: number, b: number) => number;
    readonly darttransporter_create: (a: number) => number;
    readonly darttransporter_create_transporter: (a: number, b: number) => number;
    readonly darttransporter_send_request: (a: number, b: number) => number;
    readonly darttransporter_version: (a: number) => number;
    readonly netconfighttpwasm_create: (a: number, b: number, c: number) => number;
    readonly netconfigrequestwasm_create: (a: number, b: number, c: number, d: number, e: number) => number;
    readonly nethttpheader_create: (a: number, b: number, c: number, d: number) => number;
    readonly nethttpheader_key: (a: number, b: number) => void;
    readonly nethttpheader_value: (a: number, b: number) => void;
    readonly nethttpretryconfig_create: (a: number, b: number, c: number, d: number) => number;
    readonly netrequestgrpcstream_create: (a: number, b: number, c: number, d: number) => number;
    readonly netrequestgrpcunsubscribe_create: (a: number) => number;
    readonly netrequesthttp_create: (a: number, b: number, c: number, d: number, e: number, f: number, g: number, h: number, i: number, j: number, k: number) => number;
    readonly netrequestsocketsend_create: (a: number, b: number) => number;
    readonly netrequestsocketsend_from_serde: (a: number) => number;
    readonly netrequestwasm_create: (a: number, b: number, c: number, d: number, e: number, f: number, g: number, h: number, i: number) => number;
    readonly netrequestwasm_fromserde: (a: number) => number;
    readonly netresponsegrpcsubscribe_id: (a: number) => number;
    readonly netresponsegrpcsubscribe_message: (a: number, b: number) => void;
    readonly netresponsegrpcsubscribe_status: (a: number) => number;
    readonly netresponsegrpcunary_data: (a: number, b: number) => void;
    readonly netresponsegrpcunary_message: (a: number, b: number) => void;
    readonly netresponsegrpcunary_status: (a: number) => number;
    readonly netresponsegrpcunsubscribe_id: (a: number) => number;
    readonly netresponsehttp_body: (a: number, b: number) => void;
    readonly netresponsehttp_headers: (a: number, b: number) => void;
    readonly netresponsehttp_status_code: (a: number) => number;
    readonly netresponsehttp_stream_id: (a: number) => number;
    readonly netresponsesocketstatus_code: (a: number) => number;
    readonly netresponsesocketstatus_message: (a: number, b: number) => void;
    readonly netresponsestreamdata_data: (a: number, b: number) => void;
    readonly netresponsestreamdata_id: (a: number) => number;
    readonly netresponsestreamerror_code: (a: number) => number;
    readonly netresponsestreamerror_error: (a: number) => number;
    readonly netresponsestreamerror_id: (a: number) => number;
    readonly netresponsestreamerror_message: (a: number, b: number) => void;
    readonly netresponsewasm_grpc_stream: (a: number) => number;
    readonly netresponsewasm_grpc_unary: (a: number) => number;
    readonly netresponsewasm_grpc_unsubscribe: (a: number) => number;
    readonly netresponsewasm_http: (a: number) => number;
    readonly netresponsewasm_kind: (a: number) => number;
    readonly netresponsewasm_request_id: (a: number) => number;
    readonly netresponsewasm_response_error: (a: number) => number;
    readonly netresponsewasm_stream_close: (a: number) => number;
    readonly netresponsewasm_stream_data: (a: number) => number;
    readonly netresponsewasm_stream_error: (a: number) => number;
    readonly netresponsewasm_transport_id: (a: number) => number;
    readonly start: () => void;
    readonly __wbg_intounderlyingbytesource_free: (a: number, b: number) => void;
    readonly __wbg_intounderlyingsink_free: (a: number, b: number) => void;
    readonly __wbg_intounderlyingsource_free: (a: number, b: number) => void;
    readonly intounderlyingbytesource_autoAllocateChunkSize: (a: number) => number;
    readonly intounderlyingbytesource_cancel: (a: number) => void;
    readonly intounderlyingbytesource_pull: (a: number, b: number) => number;
    readonly intounderlyingbytesource_start: (a: number, b: number) => void;
    readonly intounderlyingbytesource_type: (a: number) => number;
    readonly intounderlyingsink_abort: (a: number, b: number) => number;
    readonly intounderlyingsink_close: (a: number) => number;
    readonly intounderlyingsink_write: (a: number, b: number) => number;
    readonly intounderlyingsource_cancel: (a: number) => void;
    readonly intounderlyingsource_pull: (a: number, b: number) => number;
    readonly netrequestgrpcunary_create: (a: number, b: number, c: number, d: number) => number;
    readonly darttransporter_new: (a: number) => number;
    readonly __wbg_netrequestgrpcunary_free: (a: number, b: number) => void;
    readonly __wasm_bindgen_func_elem_1193: (a: number, b: number) => void;
    readonly __wasm_bindgen_func_elem_1198: (a: number, b: number) => void;
    readonly __wasm_bindgen_func_elem_1389: (a: number, b: number, c: number, d: number) => void;
    readonly __wasm_bindgen_func_elem_1192: (a: number, b: number, c: number) => void;
    readonly __wasm_bindgen_func_elem_1195: (a: number, b: number) => void;
    readonly __wbindgen_export: (a: number, b: number) => number;
    readonly __wbindgen_export2: (a: number, b: number, c: number, d: number) => number;
    readonly __wbindgen_export3: (a: number) => void;
    readonly __wbindgen_add_to_stack_pointer: (a: number) => number;
    readonly __wbindgen_export4: (a: number, b: number, c: number) => void;
    readonly __wbindgen_start: () => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;

/**
 * Instantiates the given `module`, which can either be bytes or
 * a precompiled `WebAssembly.Module`.
 *
 * @param {{ module: SyncInitInput }} module - Passing `SyncInitInput` directly is deprecated.
 *
 * @returns {InitOutput}
 */
export function initSync(module: { module: SyncInitInput } | SyncInitInput): InitOutput;

/**
 * If `module_or_path` is {RequestInfo} or {URL}, makes a request and
 * for everything else, calls `WebAssembly.instantiate` directly.
 *
 * @param {{ module_or_path: InitInput | Promise<InitInput> }} module_or_path - Passing `InitInput` directly is deprecated.
 *
 * @returns {Promise<InitOutput>}
 */
export default function __wbg_init (module_or_path?: { module_or_path: InitInput | Promise<InitInput> } | InitInput | Promise<InitInput>): Promise<InitOutput>;
