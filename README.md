<h1 align="center"> NoiseTorch-ng</h1>
<h3 align="center"> Noise Supression Application for PulseAudio or Pipewire</h3>
<p align="center"><img src="https://raw.githubusercontent.com/noisetorch/NoiseTorch/master/assets/icon/noisetorch.png" width="100" height="100"></p> 


<div align="center">
    
  <a href="">[![Licence][licence]][licence-url]</a>
  <a href="">[![Latest][version]][version-url]</a>
    
</div>

[licence]: https://img.shields.io/badge/License-GPLv3-blue.svg
[licence-url]: https://www.gnu.org/licenses/gpl-3.0
[version]: https://img.shields.io/github/v/release/Fabian2000/NoiseTorch?label=Latest&style=flat
[version-url]: https://github.com/Fabian2000/NoiseTorch/releases
[stars-shield]: https://img.shields.io/github/stars/Fabian2000/NoiseTorch?maxAge=2592000
[stars-url]: https://github.com/Fabian2000/NoiseTorch/stargazers/

> ### About this fork
>
> Upstream NoiseTorch has been unmaintained since 2022 and its last release,
> v0.12.2, is **broken on PipeWire 1.6 and newer**: the microphone list stays
> empty and the filter refuses to load. This fork fixes that.
>
> * **Empty device list.** PipeWire encodes the active port name of a portless
>   source as an empty string where PulseAudio sends a null-string tag. The
>   parser rejected that and discarded the *entire* source list, so every
>   microphone disappeared. Fixed in
>   [Fabian2000/pulseaudio](https://github.com/Fabian2000/pulseaudio), which
>   this fork depends on.
> * **Filter fails to load** with `No such entity`. PipeWire no longer accepts
>   absolute LADSPA plugin paths and only looks plugins up by name, but
>   NoiseTorch passed the absolute path of the plugin it extracts to `/tmp`.
>   The plugin is now installed as `nt-filter.so` and referenced by name.
>
> Older PipeWire versions and plain PulseAudio keep working unchanged.
>
> Two further differences from upstream: releases are **not signed**, and the
> **self-updater is disabled** — it is hardcoded to the upstream repository and
> would replace this build with the broken official release. Update by running
> the installer again.

NoiseTorch-ng is an easy to use open source application for Linux with PulseAudio or PipeWire. It creates a virtual microphone that suppresses noise in any application using [RNNoise](https://github.com/xiph/rnnoise). Use whichever conferencing or VOIP application you like and simply select the filtered Virtual Microphone as input to torch the sound of your mechanical keyboard, computer fans, trains and the likes.

Don't forget to leave a star ⭐ if this sounds useful to you! 

## Regarding the recent security incident

Due to a suspected security breach of the update server and code repository, there's
 been a concerted effort by the NoiseTorch community to ensure the source code and
 binaries are free from malicious code.
 
 > No malicious code has been found.
 
 You can read more about the audit that was done [here](https://github.com/noisetorch/NoiseTorch/discussions/275)
 and [here](https://github.com/noisetorch/NoiseTorch/discussions/264).
 Updates will now be retrieved from the project's releases page to avoid any risk
 of this reoccurring. We thank everyone for their trust and the love that they've
 shown towards the project in this unpleasant time. 

## Screenshot

![](https://i.imgur.com/T2wH0bl.png)

Then simply select "Filtered" as your microphone in any application. OBS, Mumble, Discord, anywhere.

![](https://i.imgur.com/nimi7Ne.png)

## Demo

Linux For Everyone has a good demo video [here](https://www.youtube.com/watch?v=DzN9rYNeeIU).

## Features
* Two click setup of your virtual denoising microphone
* A single, small, statically linked, self-contained binary

## Download & Install

[Download the latest release from GitHub](https://github.com/Fabian2000/NoiseTorch/releases),
unpack it and run the installer:

    tar -xzf NoiseTorch_x64_v0.12.3.tgz
    cd NoiseTorch_x64_v0.12.3
    ./install.sh

Linux on x86_64. The installer places the binary, desktop entry and icon under
`~/.local`, and the RNNoise LADSPA plugin in a system LADSPA directory —
PipeWire only finds plugins there, which is why this step **asks for your
password once** (via `sudo`, falling back to `pkexec`).

To keep it entirely inside your home directory, point `LADSPA_PATH` at a
writable directory instead; no password is then required, but that same
`LADSPA_PATH` must also be visible to your PipeWire session:

    LADSPA_PATH=$HOME/.ladspa ./install.sh

On first start NoiseTorch asks for your password a second time, to grant itself
`CAP_SYS_RESOURCE` — upstream behaves the same way. It needs this to raise its
memlock limit.

If your desktop does not pick up the new entry right away, tell it to refresh;
with GNOME that is `gtk-update-icon-cache`.

#### Update

This build has no self-updater. Download the newer release and run
`./install.sh` again — it overwrites the previous installation. Close NoiseTorch
first, otherwise the running instance keeps the old binary until you restart it.

#### Uninstall

    ./install.sh --uninstall

Removes the binary, desktop entry, icon and the LADSPA plugin. Your
configuration in `~/.config/noisetorch` is left untouched.

## Troubleshooting

Please see the [Troubleshooting](https://github.com/noisetorch/NoiseTorch/wiki/Troubleshooting) section in the wiki.

## Usage

Select the microphone you want to denoise, and click "Load", NoiseTorch-ng will create a virtual microphone called "Filtered Microphone" that you can select in any application. Output filtering works the same way, simply output the applications you want to filter to "Filtered Headphones".

When you're done using it, simply click "Unload" to remove it again, until you need it next time.

The slider "Voice Activation Threshold" under settings, allows you to choose how strict NoiseTorch-ng should be in only allowing your microphone to send sounds when it detects voice.. Generally you want this up as high as possible. With a decent microphone, you can turn this to the maximum of 95%. If you cut out during talking, slowly lower this strictness until you find a value that works for you.

If you set this to 0%, NoiseTorch-ng will still dampen noise, but not deactivate your microphone if it doesn't detect voice.

Please keep in mind that you will need to reload NoiseTorch-ng for these changes to apply.

Once NoiseTorch-ng has been loaded, feel free to close the window, the virtual microphone will continue working until you explicitly unload it. The NoiseTorch-ng process is not required anymore once it has been loaded.

## FAQs

### Latency

NoiseTorch-ng may introduce a small amount of latency for microphone filtering. The amount of inherent latency introduced by noise supression is 10ms, this is very low and should not be a problem. Additionally PulseAudio currently introduces a variable amount of latency that depends on your system. Lowering this latency [requires a change in PulseAudio](https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/issues/120).

Output filtering currently introduces something on the order of ~100ms with pulseaudio. This should still be fine for regular conferences, VOIPing and gaming. Maybe not for competitive gaming teams.

### Alternatives

- [noise-suppression-for-voice](https://github.com/werman/noise-suppression-for-voice): Denoising software which uses rnnoise. More complex to configure but offers more options. Requires more use of the terminal.

- [Easy Effects](https://github.com/wwmm/easyeffects): Package which offers a large number of different audio effects such as echo cancellation or noise removal. More complex to configure and only supports PipeWire. Denoising uses rnnoise.

## Building from source

Install the Go compiler from [golang.org](https://golang.org/). And make sure you have a working C++ compiler.

```shell
 git clone https://github.com/Fabian2000/NoiseTorch # Clone the repository
 cd NoiseTorch # cd into the cloned repository
 make release # build the release archive in bin/
```

`make release` produces the same archive the GitHub release ships, including
`install.sh`. Unpack it and run the installer as described above.

`make dev` builds a development binary into `bin/` instead. Note that it does
not install the LADSPA plugin, so on PipeWire >= 1.6 you still need
`nt-filter.so` (built by `make rnnoise` into `c/ladspa/rnnoise_ladspa.so`) in a
LADSPA directory for the filter to load.

## Special thanks to

* [@lawl](https://github.com/lawl) Creator of NoiseTorch
* [xiph.org](https://xiph.org)/[Mozilla's](https://mozilla.org) excellent [RNNoise](https://jmvalin.ca/demo/rnnoise/).
* [@werman](https://github.com/werman/)'s [noise-suppression-for-voice](https://github.com/werman/noise-suppression-for-voice/) for the inspiration
* [@aarzilli](https://github.com/aarzilli/)'s [nucular](https://github.com/aarzilli/nucular) GUI toolkit for Go.
* [Sallee Design](https://www.salleedesign.com) (info@salleedesign.com)'s Microphone Icon under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

