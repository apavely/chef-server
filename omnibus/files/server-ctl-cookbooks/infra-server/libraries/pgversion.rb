# frozen_string_literal: true
#
# PostgreSQL server version translation class / comparison helper
#
# Background:
#
# Since its inception, PostgreSQL has used multiple methods to designate what
# is considered a major or minor release. Legacy releases (pre-10.0) used the
# first *two* values to identify a major release (e.g., 8.4, 9.2, and 9.6 are
# all major releases). Since version 10.0's release in 2017, modern PostgreSQL
# releases follow a major.minor style similar to SemVer.
#
# The server's release version string can be inquired from the aptly-named
# read-only configuration parameter 'server_version', and the full build string
# is available through the built-in 'version()' function.
#
# The server release version is also available formatted as an integer value
# since PostgreSQL 8.2, stored in the read-only configuration parameter
# 'server_version_num'. This is designed to be a consistent, machine-readable
# format for simple and reliable programmatic version comparisons.
#
# For PostgreSQL data files, only the major version is reflected in the
# PG_VERSION file located in the PostgreSQL data directory. In theory, the
# on-disk data storage format changes only with major releases, and the
# PostgreSQL community endeavors to ensure that the data files do not require
# changes with subsequent minor releases. Consequently, minor-to-minor upgrades
# and downgrades within the same major version family do not require changes to
# the underlying data files.
#
# Basic versioning rules:
#
#   Before version 10: The first two values are considered 'major':
#     server_version = major1 . major2 . minor
#     server_version_num = (sprintf '%d%02d%02d' <- major1, major2, minor)
#
#   After version 10: Only the first value is considered 'major':
#     server_version = major . minor
#     server_version_num = (sprintf '%d%04d' <- major, minor)
#
# Versioning examples:
#
#   server_version = 9.6.22 :
#     - has major version of '9.6'
#     - has minor version of '22'
#     - has server_version_num value of 90622
#     - PG_VERSION file contains '9.6\n'
#
#   server_version = 13.4 :
#     - has major version of '13'
#     - has minor version of '4'
#     - has server_version_num value of 130004
#     - PG_VERSION file contains '13\n'
#
# Ref:
# - https://www.postgresql.org/support/versioning/
# - http://www.databasesoup.com/2016/05/changing-postgresql-version-numbering.html

class PgVersion < Gem::Version
  def major
    @major ||=
      begin
        segments = self.segments
        if segments[0].to_i >= 10
          self.class.new segments[0].to_s
        else
          self.class.new segments[0..1].join('.')
        end
      end
  end

  # We override here to also accept the server_version_num value, and coerce
  # the value into a proper dotted version string.
  def self.new(input)
    if input.is_a?(self)
      super
    elsif input.to_i >= 100000
      new input.to_s
               .match(/([0-9]+)([0-9]{4})$/)
               .captures
               .map(&:to_i)
               .join('.')
    elsif input.to_i >= 80200
      new input.to_s
               .match(/([0-9]+)([0-9]{2})([0-9]{2})$/)
               .captures
               .map(&:to_i)
               .join('.')
    else
      super
    end
  end

  # Return the version in server_version_num integer format, if server_version
  # is at or greater than 8.2, otherwise, zero.
  def to_i
    segments = self.segments
    if segments[0].to_i >= 10
      format('%<major>d%<minor>04d',
             major: segments[0].to_i,
             minor: segments[1].to_i
            ).to_i
    elsif segments[0].to_i == 8 && segments[1].to_i >= 2 ||
          segments[0].to_i == 9
      format('%<major1>d%<major2>02d%<minor>02d',
             major1: segments[0].to_i,
             major2: segments[1].to_i,
             minor: segments[2].to_i
            ).to_i
    else
      nil.to_i
    end
  end
end
