function [WhitenedPower, FooofFrequencies] = whiten_spectrum(Power, Frequencies, FooofFittingRange)
% uses FOOOF

FooofModel = fooof(Frequencies, Power, FooofFittingRange, struct(), true);
FooofFrequencies = FooofModel.freqs;

WhitenedPower = 10.^FooofModel.power_spectrum-10.^FooofModel.ap_fit;
% WhitenedPower = FooofModel.power_spectrum-FooofModel.ap_fit;
