#include "hatsizer.h"
#include <math.h>

// Just a lil' helper that converts centimeters to inches.
// Private like my stash of salted caramels.
static float cm_to_inches(float cm) {
    return cm / 2.54f;
}

HatSize hat_sizer_get_size(HatFitInfo info) {
    float inches = cm_to_inches(info.head_circumference_cm);

    if (inches < 20.5f) return HAT_SIZE_XS;
    else if (inches < 21.5f) return HAT_SIZE_S;
    else if (inches < 22.5f) return HAT_SIZE_M;
    else if (inches < 23.5f) return HAT_SIZE_L;
    else if (inches < 24.5f) return HAT_SIZE_XL;
    else return HAT_SIZE_UNKNOWN; // For heads that don’t play by the rules.
}

const char* hat_sizer_size_to_string(HatSize size) {
    switch (size) {
        case HAT_SIZE_XS: return "Extra Small";
        case HAT_SIZE_S:  return "Small";
        case HAT_SIZE_M:  return "Medium";
        case HAT_SIZE_L:  return "Large";
        case HAT_SIZE_XL: return "Extra Large";
        default:          return "Unknown Size (custom hat required)";
    }
}

float hat_sizer_roundness_score(HatFitInfo info) {
    // Normalize the circumference between 50 and 64 cm
    float norm = (info.head_circumference_cm - 50.0f) / (64.0f - 50.0f);
    if (norm < 0.0f) norm = 0.0f;
    if (norm > 1.0f) norm = 1.0f;

    // Use a sine curve to simulate a “roundness sweet spot”
    return (sinf(norm * 3.14159f) + 1.0f) / 2.0f;
}
