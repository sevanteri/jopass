#include <janet.h>
static const unsigned char bytes[] = {215, 205, 0, 152, 0, 0, 4, 0, 0, 205, 127, 255, 255, 255, 3, 7, 206, 4, 109, 97, 105, 110, 206, 10, 109, 97, 105, 110, 46, 106, 97, 110, 101, 116, 215, 205, 0, 152, 0, 0, 2, 0, 0, 0, 2, 5, 206, 11, 99, 104, 101, 99, 107, 45, 108, 111, 103, 105, 110, 218, 1, 206, 21, 115, 101, 115, 115, 105, 111, 110, 32, 107, 101, 121, 32, 105, 115, 32, 118, 97, 108, 105, 100, 63, 216, 5, 112, 114, 105, 110, 116, 44, 0, 0, 0, 42, 1, 0, 0, 47, 1, 0, 0, 42, 1, 1, 0, 52, 1, 0, 0, 2, 1, 1, 3, 0, 3, 0, 3, 0, 3, 215, 205, 0, 152, 0, 0, 2, 0, 0, 0, 2, 5, 206, 11, 99, 104, 101, 99, 107, 45, 99, 97, 99, 104, 101, 218, 1, 206, 43, 99, 97, 99, 104, 101, 32, 105, 116, 101, 109, 115, 32, 105, 102, 32, 99, 97, 99, 104, 101, 32, 105, 115, 32, 101, 109, 112, 116, 121, 44, 32, 97, 110, 100, 32, 111, 110, 32, 108, 111, 103, 105, 110, 218, 4, 44, 0, 0, 0, 42, 1, 0, 0, 47, 1, 0, 0, 42, 1, 1, 0, 52, 1, 0, 0, 5, 1, 1, 3, 0, 3, 0, 3, 0, 3, 215, 205, 0, 152, 0, 0, 2, 0, 0, 0, 2, 5, 206, 10, 112, 97, 114, 115, 101, 45, 97, 114, 103, 115, 218, 1, 206, 8, 100, 111, 32, 115, 116, 117, 102, 102, 218, 4, 44, 0, 0, 0, 42, 1, 0, 0, 47, 1, 0, 0, 42, 1, 1, 0, 52, 1, 0, 0, 8, 1, 1, 3, 0, 3, 0, 3, 0, 3, 44, 0, 0, 0, 42, 2, 0, 0, 51, 1, 2, 0, 42, 3, 1, 0, 51, 2, 3, 0, 42, 3, 2, 0, 52, 3, 0, 0, 11, 1, 1, 3, 0, 3, 1, 3, 0, 3, 1, 3, 0, 3};

const unsigned char *janet_payload_image_embed = bytes;
size_t janet_payload_image_embed_size = sizeof(bytes);

int main(int argc, const char **argv) {
    janet_init();

    /* Get core env */
    JanetTable *env = janet_core_env(NULL);
    JanetTable *lookup = janet_env_lookup(env);
    JanetTable *temptab;
    int handle = janet_gclock();

    /* Load natives into unmarshalling dictionary */

        /* Unmarshal bytecode */
    Janet marsh_out = janet_unmarshal(
      janet_payload_image_embed,
      janet_payload_image_embed_size,
      0,
      lookup,
      NULL);

    /* Verify the marshalled object is a function */
    if (!janet_checktype(marsh_out, JANET_FUNCTION)) {
        fprintf(stderr, "invalid bytecode image - expected function.");
        return 1;
    }
    JanetFunction *jfunc = janet_unwrap_function(marsh_out);

    /* Check arity */
    janet_arity(argc, jfunc->def->min_arity, jfunc->def->max_arity);

    /* Collect command line arguments */
    JanetArray *args = janet_array(argc);
    for (int i = 0; i < argc; i++) {
        janet_array_push(args, janet_cstringv(argv[i]));
    }

    /* Create enviornment */
    temptab = janet_table(0);
    temptab = env;
    janet_table_put(temptab, janet_ckeywordv("args"), janet_wrap_array(args));
    janet_gcroot(janet_wrap_table(temptab));

    /* Unlock GC */
    janet_gcunlock(handle);

    /* Run everything */
    JanetFiber *fiber = janet_fiber(jfunc, 64, argc, argc ? args->data : NULL);
    fiber->env = temptab;
    Janet out;
    JanetSignal result = janet_continue(fiber, janet_wrap_nil(), &out);
    if (result != JANET_SIGNAL_OK && result != JANET_SIGNAL_EVENT) {
      janet_stacktrace(fiber, out);
      janet_deinit();
      return result;
    }
#ifdef JANET_NET
    janet_loop();
#endif
    janet_deinit();
    return 0;
}
