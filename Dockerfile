FROM lscr.io/linuxserver/beets:latest

# Install required Python packages for beets plugins
RUN pip install --no-cache-dir \
    beets[badfiles,chroma,lastgenre,lastimport,discogs,replaygain,fetchart,lyrics,mbsubmit,mbsync] \
    beetcamp \
    pylast \
    watchdog \
    beets-copyartifacts3 \
    beautifulsoup4 \
    discogs-client \
    requests
