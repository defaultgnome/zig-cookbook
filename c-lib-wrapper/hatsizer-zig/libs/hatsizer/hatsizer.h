#ifndef HAT_SIZER_H
#define HAT_SIZER_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    HAT_SIZE_XS,
    HAT_SIZE_S,
    HAT_SIZE_M,
    HAT_SIZE_L,
    HAT_SIZE_XL,
    HAT_SIZE_UNKNOWN
} HatSize;

typedef struct {
    float head_circumference_cm; // Big fancy word for the size o' yer noggin
} HatFitInfo;

// Returns your hat size based on your head circumference (in cm).
HatSize hat_sizer_get_size(HatFitInfo info);

// Optional: get a string for debuggin’ or bragin’ purposes.
const char* hat_sizer_size_to_string(HatSize size);

// Returns a roundness score from 0.0 to 1.0.
// It’s nonsense—but it’s fancy nonsense, like sayin’ “tertiary cranial symmetry coefficient” in a pub.
float hat_sizer_roundness_score(HatFitInfo info);

#ifdef __cplusplus
}
#endif

#endif // HAT_SIZER_H
