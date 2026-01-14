#! /usr/bin/env fan

class CompareTimeZones
{
  static Int main(Str[] args)
  {
    if (args.first == "-dump") return CompareTimeZones().onDump(args[1])
    return CompareTimeZones().onCompare(args[0], args[1])
    return 0
  }

  Int onDump(Str outName)
  {
    f := outName.toUri.toFile
    out := f.out

    aliases := Env.cur.homeDir.plus(`etc/sys/timezone-aliases.props`).readProps

    TimeZone.listFullNames.rw.sort.each |n| { out.printLine(n) }
    out.printLine("--- Aliases")
    aliases.keys.sort.each |key| { out.printLine("${key}=${aliases[key]}") }
    out.close

    return 0
  }

  Int onCompare(Str oldName, Str newName)
  {
    out := `./compare.txt`.toFile.out
    old := Tzs(oldName.toUri.toFile).load
    cur := Tzs(newName.toUri.toFile).load
    compareTzs(out, old, cur)
    out.close
    return 0
  }

  private Void compareTzs(OutStream out, Tzs old, Tzs cur)
  {
    newTz := Str:Bool[:] { ordered = true }
    newAlias := Str:Str[:] { ordered = true }
    changedAlias := Str:Str[:] { ordered = true }
    other := Str:Str[:] { ordered = true }

    old.names.each |v, n|
    {
      if (cur.names[n] == null)
      {
        if (cur.aliases[n] == null) other.add(n, "Removed timezone")
        else changedAlias[n] = cur.aliases[n]
      }
    }
    old.aliases.each |v, n|
    {
      if (cur.aliases[n] == null)
      {
        if (cur.names[n] == null) other.add(n, "Removed alias")
        else other.add(n, "Changed from alias to timezone")
      }
    }
    cur.names.each |v, n|
    {
      if (old.names[n] == null)
      {
        if (old.aliases[n] == null) newTz[n] = true
      }
    }
    cur.aliases.each |v, n|
    {
      if (old.aliases[n] == null)
      {
        if (old.names[n] == null) newAlias.add(n, v)
        // if (changes.containsKey(n)) throw Err("${n} ${changes[n]} and New Alias")
        // changes.add(n, "New alias")
      }
    }
    writeMap(out, "New Timezones", newTz)
    writeMap(out, "New Aliases", newAlias)
    writeMap(out, "Changed to Alias", changedAlias)
    writeMap(out, "Other Changes", other)
  }

  private Void writeMap(OutStream out, Str header, Map m)
  {
    out.printLine("${header}\n#####################")
    m.keys.sort.each |n|
    {
      v := m[n]
      if (v is Bool) out.printLine(n)
      else out.printLine("${n}: ${v}")
    }
    out.printLine
  }
}

internal class Tzs
{
  new make(File f)
  {
    this.f = f
  }

  private File f
  Str:Bool names := [:]
  Str:Str aliases := [:]

  This load()
  {
    inNames := true
    f.eachLine |line|
    {
      if (line.startsWith("---")) { inNames = false; return }
      if (inNames) { names[line] = true }
      else
      {
        toks := line.split('=')
        aliases[toks.first] = toks.last
      }
    }
    return this
  }
}