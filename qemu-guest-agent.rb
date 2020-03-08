class QemuGuestAgent < Formula
  desc "x86 and PowerPC Emulator"
  homepage "https://www.qemu.org/"
  url "https://download.qemu.org/qemu-4.2.0.tar.xz"
  sha256 "d3481d4108ce211a053ef15be69af1bdd9dde1510fda80d92be0f6c3e98768f0"
  head "https://git.qemu.org/git/qemu.git"

  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "glib"

  def install
    ENV["LIBTOOL"] = "glibtool"

    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cc=#{ENV.cc}
      --disable-system
      --disable-user
      --disable-tools
      --enable-guest-agent
    ]

    system "./configure", *args
    system "make", "V=1", "qemu-ga"

    bin.install "qemu-ga"
  end

  plist_options startup: true

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/qemu-ga</string>
          <string>-p</string>
          <string>/dev/tty.serial1</string>
          <string>-t</string>
          <string>/var/run</string>
          <string>-m</string>
          <string>isa-serial</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
      </dict>
    </plist>
  EOS
  end

  test do
    expected = "QEMU Guest Agent"
    assert_match expected, shell_output("#{bin}/qemu-ga --version")
  end
end

__END__
diff --git a/configure b/configure
index 557e438..da22aea 100755
--- a/configure
+++ b/configure
@@ -6217,9 +6217,7 @@ fi
 # Probe for guest agent support/options
 
 if [ "$guest_agent" != "no" ]; then
-  if [ "$softmmu" = no -a "$want_tools" = no ] ; then
-      guest_agent=no
-  elif [ "$linux" = "yes" -o "$bsd" = "yes" -o "$solaris" = "yes" -o "$mingw32" = "yes" ] ; then
+  if [ "$linux" = "yes" -o "$bsd" = "yes" -o "$solaris" = "yes" -o "$mingw32" = "yes" ] ; then
       tools="qemu-ga\$(EXESUF) $tools"
       guest_agent=yes
   elif [ "$guest_agent" != yes ]; then
diff --git a/qga/commands-posix.c b/qga/commands-posix.c
index 93474ff..105f12f 100644
--- a/qga/commands-posix.c
+++ b/qga/commands-posix.c
@@ -89,9 +89,9 @@ void qmp_guest_shutdown(bool has_mode, const char *mode, Error **errp)
 
     slog("guest-shutdown called, mode: %s", mode);
     if (!has_mode || strcmp(mode, "powerdown") == 0) {
-        shutdown_flag = "-P";
+        shutdown_flag = "-h";
     } else if (strcmp(mode, "halt") == 0) {
-        shutdown_flag = "-H";
+        shutdown_flag = "-h";
     } else if (strcmp(mode, "reboot") == 0) {
         shutdown_flag = "-r";
     } else {
@@ -108,7 +108,7 @@ void qmp_guest_shutdown(bool has_mode, const char *mode, Error **errp)
         reopen_fd_to_null(1);
         reopen_fd_to_null(2);
 
-        execle("/sbin/shutdown", "shutdown", "-h", shutdown_flag, "+0",
+        execle("/sbin/shutdown", "shutdown", shutdown_flag, "+0",
                "hypervisor initiated shutdown", (char*)NULL, environ);
         _exit(EXIT_FAILURE);
     } else if (pid < 0) {
