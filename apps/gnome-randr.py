#!/bin/env python3

# source: https://gitlab.com/Oschowa/gnome-randr
# alternative: https://github.com/maxwellainatchi/gnome-randr-rust

import sys, os, dbus
from collections import defaultdict

# from stackoverflow.com/questions/5369723
nested_dict = lambda: defaultdict(nested_dict)

def fatal(str):
    print(str)
    quit(1)

def warn(str):
    print('\n! {} !\n'.format(str))

def usage():
    print('usage: {} [options]\n'
          '\twhere options are:\n'
          '\t--current\n'
          '\t--dry-run\n'
          '\t--persistent\n'
          '\t--global-scale <global-scale>\n'
          '\t--output <output>\n'
          '\t\t--auto\n'
          '\t\t--mode <mode>\n'
          '\t\t--rate <rate>\n'
          '\t\t--scale <scale>\n'
          '\t\t--off\n'
          '\t\t--right-of <output>\n'
          '\t\t--left-of <output>\n'
          '\t\t--above <output>\n'
          '\t\t--below <output>\n'
          '\t\t--same-as <output>\n'
          '\t\t--rotate normal,inverted,left,right\n'
          '\t\t--primary\n'.format(os.path.basename(sys.argv[0])))
    quit()

def get_mode_by_res(res, monitor):
    for md in monitor[1]:
        res_str = '{}x{}'.format(md[1], md[2])
        if res_str == res:
            return md

def get_mode_by_id(mode_id, monitor):
    for md in monitor[1]:
        if md[0] == mode_id:
            return md

def mode_has_rate(res, rate, monitor):
    for md in monitor[1]:
        res_str = '{}x{}'.format(md[1], md[2])
        if res_str == res and round(md[3]) == round(rate):
            return md

def get_pref_mode(monitor):
    for md in monitor[1]:
        if 'is-preferred' in md[6]:
            return md

def get_current_mode(monitor):
    for md in monitor[1]:
        if 'is-current' in md[6]:
            return md

def has_scale(scale, mode):
    for s in mode[5]:
        if s == scale:
            return s

def mode_props_to_str(props):
    str = ''
    if 'is-current' in props:
        str += '*'
    if 'is-preferred' in props:
        str += '+'
    if 'is-interlaced' in props:
        str += 'i'
    return str

def modes_to_str_pretty(modes):
    mode_strings = dict()

    len_max = 1
    for md in modes:
        res_str = '{:>13}'.format('{}x{}'.format(md[1], md[2]))
        rate_str = '{:>11}'.format('{:>8.2f}{:<3}'
                                   .format(md[3], mode_props_to_str(md[6])))
        scale_str = scales_to_str(md[4], md[5])

        if not res_str in mode_strings:
            mode_strings[res_str] = dict()
            mode_strings[res_str]['rate-str'] = rate_str
            mode_strings[res_str]['scale-str'] = scale_str
        else:
            mode_strings[res_str]['rate-str'] += rate_str

        len_pre = len(res_str) + len(mode_strings[res_str]['rate-str'])
        if len_pre > len_max:
            len_max = len_pre
        mode_strings[res_str]['len-pre'] = len_pre

    str = ''
    for res_str, v in mode_strings.items():
        ind = len_max - v['len-pre'] + 4
        str += res_str + v['rate-str'] + ' ' * ind + v['scale-str'] + '\n'
    return str

def scales_to_str(pref_scale, scales):
    str = '['
    for n in range(len(scales)):
        str += 'x{0:.1f}'.format(scales[n])
        if scales[n] == pref_scale:
            str += '+'
        if n + 1 >= len(scales):
            str += ']'
        else:
            str += ', '
    return str

def bool_to_str(b):
    return {
        True: 'yes',
        False: 'no'
    }.get(b)

def rot_to_trans(r):
    return {
        'normal': 0,
        'inverted': 6,
        'left': 1,
        'right': 3
    }.get(r, 0)

def trans_to_rot(t):
    assert(t in [0, 6, 1, 3])
    return {
        0: 'normal',
        6: 'inverted',
        1: 'left',
        3: 'right'
    }.get(t)

def trans_needs_w_h_swap(old_trans, new_trans):
    if old_trans in [0, 6] and new_trans in [1, 3]:
        return True
    elif old_trans in [1, 3] and new_trans in [0, 6]:
        return True
    else:
        return False

def mode_id_to_vals(mode_id):
    w, h_rate = mode_id.split('x')
    h, rate = h_rate.split('@')
    return (int(w), int(h), float(rate))

def find_best_matching_mode(monitors):
    matches = []

    # get a list of all matching modes
    # for all modes of the first monitor
    for md in monitors[0][1]:
        # for all remaining monitors
        for m in monitors[1:]:
            for _md in m[1]:
                if md[0] == _md[0]:
                    # merge properties dict to preserve prefered mode prop
                    md[6].update(_md[6])
                    matches.append(md)

    if len(matches) == 0:
        return None

    # sort by resolution and rate
    matches.sort(key = lambda x: (x[1] * x[2], x[3]), reverse = True)

    # if a prefered mode is among the matches, use it
    for md in matches:
        if 'is-preferred' in md[6]:
            return md

    # otherwise use the topmost
    return matches[0]

def get_mirror_mode(config_info, outputs):
    monitors = []

    for out in outputs:
        monitors.append(config_info.output_config[out]['monitor'])

    mode = find_best_matching_mode(monitors)
    if not mode:
        fatal('can\'t mirror outputs {}'.format(outputs))
    else:
        return mode

def get_monmap(monitors, logical_monitors):
    # one more as we have monitors to simplify shift/compact logic
    n_cells = len(monitors) + 1
    monmap = [[[] for _ in range(n_cells)] for __ in range(n_cells)] 
    lm_list = logical_monitors.copy()

    col_idx = 0
    while True:
        min_x = 320000
        to_set = None
        for lm in lm_list:
            x = lm[0]
            y = lm[1]

            if y > 0:
                continue

            if x < min_x:
                min_x = x
                to_set = lm

        if not to_set:
            break
        lm_list.remove(to_set)
        outputs = []
        for m in to_set[5]:
            outputs.append(m[0])
        monmap[0][col_idx] = outputs

        cur_x = to_set[0]
        row_idx = 1
        while True:
            min_y = 32000
            to_set = None
            for lm in lm_list:
                x = lm[0]
                y = lm[1]

                if x != cur_x:
                    continue

                if y < min_y:
                    min_y = y
                    to_set = lm

            if not to_set:
                break
            lm_list.remove(to_set)
            outputs = []
            for m in to_set[5]:
                outputs.append(m[0])
            monmap[row_idx][col_idx] = outputs
            row_idx += 1

        col_idx += 1

    return monmap

def monmap_find_output_idx(monmap, output):
    out_idx = None
    for r, row in enumerate(monmap):
        for c, cell in enumerate(row):
            for out in cell:
                if out == output:
                    out_idx = (r, c)
    return out_idx

def monmap_idx_free(monmap, idx):
    if len(monmap[idx[0]][idx[1]]) == 0:
        return True
    else:
        return False

def monmap_shift(monmap, at_idx, direction):
    assert direction in ['>', 'v']

    if direction == '>':
        next_idx = (at_idx[0], at_idx[1] + 1)
    elif direction == 'v':
        next_idx = (at_idx[0] + 1, at_idx[1])

    if not monmap_idx_free(monmap, next_idx):
        monmap_shift(monmap, next_idx, direction)

    monmap[next_idx[0]][next_idx[1]] = monmap[at_idx[0]][at_idx[1]]
    monmap[at_idx[0]][at_idx[1]] = []

def monmap_compact(monmap, at_idx):
    if not monmap_idx_free(monmap, at_idx):
        return

    # try compacting vertically first
    next_idx = (at_idx[0] + 1, at_idx[1])
    if monmap_idx_free(monmap, next_idx):
        # then horizontally
        next_idx = (at_idx[0], at_idx[1] + 1)
        if monmap_idx_free(monmap, next_idx):
            return

    monmap[at_idx[0]][at_idx[1]] = monmap[next_idx[0]][next_idx[1]]
    monmap[next_idx[0]][next_idx[1]] = []

    monmap_compact(monmap, next_idx)

def monmap_add_output_next_free(monmap, output):
    for r, row in enumerate(monmap):
        for c, cell in enumerate(row):
            if len(cell) == 0:
                cell.append(output)
                return

def monmap_remove_output(monmap, output):
    out_idx = monmap_find_output_idx(monmap, output)
    if out_idx:
        monmap[out_idx[0]][out_idx[1]].remove(output)
        monmap_compact(monmap, out_idx)

def monmap_move_output(monmap, output, rel_output, relation):
    out_idx = monmap_find_output_idx(monmap, output)
    rel_idx = monmap_find_output_idx(monmap, rel_output)

    assert(out_idx and rel_idx)

    if relation == 'left-of':
        new_idx = (rel_idx[0], rel_idx[1] - 1)
        shift_direction = '>'
    elif relation == 'right-of':
        new_idx = (rel_idx[0], rel_idx[1] + 1)
        shift_direction = '>'
    elif relation == 'above':
        new_idx = (rel_idx[0] - 1, rel_idx[1])
        shift_direction = 'v'
    elif relation == 'below':
        new_idx = (rel_idx[0] + 1, rel_idx[1])
        shift_direction = 'v'
    elif relation == 'same-as':
        new_idx = rel_idx
    else:
        assert(0)

    if new_idx[0] < 0:
        new_idx = (0, new_idx[1])

    if new_idx[1] < 0:
        new_idx = (new_idx[0], 0)

    if new_idx == out_idx:
        return

    # remove the output first, so it is not considered while shifting
    monmap[out_idx[0]][out_idx[1]].remove(output)

    if relation != 'same-as' and not monmap_idx_free(monmap, new_idx):
        monmap_shift(monmap, new_idx, shift_direction)

    monmap[new_idx[0]][new_idx[1]].append(output)
    monmap_compact(monmap, out_idx)


def monmap_to_lm(config_info, monmap):
    new_lm = []
    max_entries = len(monmap) - 1
    y_info = [[0, 0, 0] for _ in range(max_entries)]

    row_idx = 0
    while row_idx < max_entries:
        cur_x = 0
        # prefer the y value of neighbor if possible
        cur_y = 0
        col_idx = 0
        while col_idx < max_entries:
            cell = monmap[row_idx][col_idx]
            if len(cell) == 0:
                cur_y = 0
                col_idx += 1
                continue

            conf = config_info.output_config[cell[0]]
            if len(cell) > 1:
                mode = get_mirror_mode(config_info, cell)
            else:
                mode = conf['mode-info']
            mode_id = mode[0]
            # use the conf values which accounts for rotation
            w = conf['w']
            h = conf['h']

            x = y_info[col_idx][0]
            y = y_info[col_idx][2]

            if x < cur_x:
                x = cur_x

            if cur_y > y:
                y = cur_y

            end_x = x + w

            for col in y_info:
                if (col[0] <= x < col[1] or
                    col[0] < end_x <= col[1]):
                    if col[2] > y:
                        y = col[2]

            y_info[col_idx] = [x, end_x, y + h]

            phy = []
            is_primary = False
            # if no primary lm is specified, choose output at 0,0
            if not config_info.primary and row_idx == 0 and col_idx == 0:
                is_primary = True
            for out in cell:
                if out == config_info.primary:
                    is_primary = True
                phy.append([out, mode_id, {}])
            lm = [x, y, conf['scale'], conf['trans'], is_primary, phy]
            new_lm.append(lm)

            cur_x = end_x
            cur_y = y
            col_idx += 1
        row_idx += 1

    return new_lm

class ActionRequest:

    def __init__(self):
        self.print_current = False
        self.dry_run = False
        # 1: temporary, 2: persistent
        self.config_method = 1
        self.global_scale = None
        self.primary = None
        self.output_config = nested_dict()

class ConfigInfo:

    def __init_properties(self, props):
        if 'max-screen-size' in props:
            self.x_max = props['max-screen-size'][0]
            self.y_max = props['max-screen-size'][1]
        else:
            self.x_max = 0
            self.y_max = 0
        if 'layout-mode' in props:
            self.layout_mode = {1: 'physical',
                                2: 'logical'}.get(props['layout-mode'])
        else:
            self.layout_mode = 'unknown'
        if ('global-scale-required' in props and 
            props['global-scale-required'] == True):
            self.global_scale_required = True
        else:
            self.global_scale_required = False
        if ('supports-mirroring' in props and
            props['supports-mirroring'] == False):
            self.supports_mirroring = False
        else:
            self.supports_mirroring = True
        if ('supports-changing-layout-mode' in props and 
            props['supports-changing-layout-mode'] == True):
            self.supports_changing_layout_mode = True
        else:
            self.supports_changing_layout_mode = False

    def __init_output_config(self, monitors, logical_monitors):
        self.global_scale = None
        self.output_config = nested_dict()

        for lm in logical_monitors:
            scale = lm[2]
            if self.global_scale_required == True:
                self.global_scale = scale

            # save the first ouput of the primary logical monitor as primary
            if lm[4] == True:
                self.primary = lm[5][0][0]

            for m in lm[5]:
                output = m[0]
                conf = self.output_config[output]
                # the monitor object returned by GetCurrentState does not
                # contain all necessary information
                monitor = self.get_monitor_by_output(output)
                md = get_current_mode(monitor)
                w, h, r = mode_id_to_vals(md[0])

                conf['monitor'] = monitor
                conf['mode-info'] = md
                # to later dectect changed config easier
                conf['old-mode-id'] = md[0]
                conf['res'] = '{}x{}'.format(w, h)
                conf['w'] = w
                conf['h'] = h
                conf['rate'] = r
                conf['scale'] = scale
                conf['trans'] = lm[3]


    def __init__(self, serial, monitors, logical_monitors, properties):
        self.serial = serial
        self.monitors = monitors
        self.logical_monitors = logical_monitors
        self.__init_properties(properties)
        self.__init_output_config(monitors, logical_monitors)
        self.monmap = get_monmap(monitors, logical_monitors)

    def set_output_defaults(self, output, monitor):
        conf = self.output_config[output]
        conf['monitor'] = monitor
        conf['mode-info'] = None
        conf['res'] = 'off'
        conf['w'] = 0
        conf['h'] = 0
        conf['rate'] = 0.0
        conf['scale'] = 1.0
        conf['trans'] = 0

    def update_output_config(self, requested_actions):
        for out, conf in requested_actions.output_config.items():

            monitor = self.get_monitor_by_output(out)
            if not monitor:
                warn('output {} does not exist'.format(out))
                continue

            if not out in self.output_config:
                # output was not previously enabled
                # so set some defaults
                self.set_output_defaults(out, monitor)

            if 'res' in conf:
                self.output_set_mode_by_res(out, conf['res'])
            if 'rate' in conf:
                self.output_set_rate(out, conf['rate'])
            if 'scale' in conf:
                self.output_set_scale(out, conf['scale'])
            if 'trans' in conf:
                self.output_set_trans(out, conf['trans'])

        if requested_actions.primary:
            self.primary = requested_actions.primary

        if requested_actions.global_scale:
            self.global_scale = requested_actions.global_scale

        if self.global_scale:
            print('global scale is set; ignoring per monitor scales')
            for out in self.output_config.keys():
                self.output_set_scale(out, self.global_scale)

        # another loop to make sure mode changes are applied before relations
        for out, conf in requested_actions.output_config.items():
            if 'relation' in conf:
                self.output_set_relation(out, conf['relation'])

    def output_set_relation(self, output, relation):
        conf = self.output_config[output]
        rel_out = relation[1]
        rel_conf = self.output_config[rel_out]

        if conf['res'] == 'off':
            return

        if rel_conf and rel_conf['res'] != 'off':
            monmap_move_output(self.monmap, output, rel_out, relation[0])
        else:
            warn('{} can\'t be relative to disabled or unavailable output {}'
                  .format(output, rel_out))

    def output_set_trans(self, output, trans):
        conf = self.output_config[output]

        if conf['res'] == 'off':
            return

        # switch width and height if neccessary
        if trans_needs_w_h_swap(conf['trans'], trans):
            old_w = conf['w']
            conf['w'] = conf['h']
            conf['h'] = old_w
        conf['trans'] = trans

    def output_set_scale(self, output, scale):
        conf = self.output_config[output]

        if conf['res'] == 'off':
            return

        if has_scale(scale, conf['mode-info']):
            conf['scale'] = scale
        else:
            warn('scale {} not available for output {}@{}'
                  .format(scale, output, conf['res']))

    def output_set_rate(self, output, rate):
        conf = self.output_config[output]
        monitor = conf['monitor']

        if conf['res'] == 'off':
            return

        new_mode = mode_has_rate(conf['res'], rate, monitor)

        if new_mode:
            conf['mode-info'] = new_mode
            conf['rate'] = rate
        else:
            warn('rate {} not available for output {}@{}'
                  .format(rate, output, conf['res']))

    def output_set_mode_by_res(self, output, res):
        conf = self.output_config[output]
        monitor = conf['monitor']
        old_res = conf['res']

        if res == 'off':
            conf['res'] = 'off'
            monmap_remove_output(self.monmap, output)
            if self.primary == output:
                self.primary = None
            return

        if res == 'auto':
            new_mode = get_pref_mode(monitor)
        else:
            new_mode = get_mode_by_res(res, monitor)

        if new_mode:
            conf['mode-info'] = new_mode
            conf['res'] = res
            conf['w'] = new_mode[1]
            conf['h'] = new_mode[2]
            conf['rate'] = new_mode[3]
            if old_res == 'off':
                monmap_add_output_next_free(self.monmap, output)
        else:
            warn('mode {} not available for output {}'
                  .format(res, output))

    def get_monitor_by_output(self, output):
        for m in self.monitors:
            if m[0][0] == output:
                return m

    def config_changed(self, new_lm):
        old_lm = self.logical_monitors

        if len(old_lm) != len(new_lm):
            return True

        for nlm in new_lm:
            olm = None
            # find old lm at same position
            for lm in old_lm:
                if lm[0] == nlm[0] and lm[1] == nlm[1]:
                    olm = lm
                    break
            # compare scale, trans, primary and number of physical monitors
            if (not olm or
                olm[2] != nlm[2] or
                olm[3] != nlm[3] or
                olm[4] != nlm[4] or
                len(olm[5]) != len(nlm[5])):
                return True
            # for all physical monitors
            for nm in nlm[5]:
                om = None
                # search for monitor with same connector name
                for m in olm[5]:
                    if m[0] == nm[0]:
                        om = m
                        break
                # check if mode differs
                if (not om or
                    nm[1] != self.output_config[om[0]]['old-mode-id']):
                    return True

        return False

    def print_properties(self):
        print('max-screen-size: {}x{}\n'
              'layout-mode: {}\n'
              'global-scale-required: {}\n'
              'supports-mirroring: {}\n'
              'supports-changing-layout-mode: {}\n'.format(
              self.x_max, self.y_max,
              self.layout_mode,
              bool_to_str(self.global_scale_required),
              bool_to_str(self.supports_mirroring),
              bool_to_str(self.supports_changing_layout_mode)))


    def print_current_config(self):
        for n in range(len(self.logical_monitors)):
            lm = self.logical_monitors[n]
            print('logical monitor {}:\n'
                  'x: {} y: {}, scale: {}, rotation: {}, primary: {}\n'
                  'associated physical monitors:'.format(
                  n,
                  lm[0], lm[1], lm[2],
                  trans_to_rot(lm[3]), bool_to_str(lm[4])))
            for m in lm[5]:
                print('\t{} {}'.format(m[0], m[2]))
            print()
        for m in self.monitors:
            print('{} {} {} {}'.format(m[0][0], m[0][1], m[0][2], m[0][3]))
            print(modes_to_str_pretty(m[1]))

def print_new_config(logical_monitors):
    print('new monitor configuration:')
    for n in range(len(logical_monitors)):
        lm = logical_monitors[n]
        print('logical monitor {}:'.format(n))
        print('x: {} y: {}, scale: {}, rotation: {}, primary: {}'.format(
              lm[0], lm[1], lm[2], trans_to_rot(lm[3]), bool_to_str(lm[4])))
        print('associated physical monitors:')
        for m in lm[5]:
            print('\t{} {}'.format(m[0], m[1]))
        print()

requested_actions = ActionRequest()

config_output = None
n = 1
while n < len(sys.argv):
    arg = sys.argv[n]
    n += 1

    if arg == '-h' or arg == '--help':
        usage()
    elif arg == '--current':
        requested_actions.print_current = True
    elif arg == '--dry-run':
        requested_actions.dry_run = True
    elif arg == '--persistent':
        requested_actions.config_method = 2
    elif arg == '--global-scale':
        if n >= len(sys.argv):
            fatal('{} requires an argument'.format(arg))
        requested_actions.global_scale = float(sys.argv[n])
        n += 1
    elif arg == '--output':
        if n >= len(sys.argv):
            fatal('{} requires an argument'.format(arg))
        config_output = sys.argv[n]
        n += 1
    elif arg == '--auto':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        requested_actions.output_config[config_output]['res'] = 'auto'
    elif arg == '--mode':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        if n >= len(sys.argv):
            fatal('{} requires an argument'.format(arg))
        requested_actions.output_config[config_output]['res'] = sys.argv[n]
        n += 1
    elif arg == '--rate':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        if n >= len(sys.argv):
            fatal('{} requires an argument'.format(arg))
        requested_actions.output_config[config_output]['rate'] = \
            float(sys.argv[n])
        n += 1
    elif arg == '--scale':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        if n >= len(sys.argv):
            fatal('{} requires an argument'.format(arg))
        requested_actions.output_config[config_output]['scale'] = \
            float(sys.argv[n])
        n += 1
    elif arg == '--off':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        requested_actions.output_config[config_output]['res'] = 'off'
    elif arg == '--right-of':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        if n >= len(sys.argv):
            fatal('{} requires an argument'.format(arg))
        requested_actions.output_config[config_output]['relation'] = \
            ('right-of', sys.argv[n]) 
        n += 1
    elif arg == '--left-of':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        if n >= len(sys.argv):
            fatal('{} requires an argument'.format(arg))
        requested_actions.output_config[config_output]['relation'] = \
            ('left-of', sys.argv[n])
        n += 1
    elif arg == '--above':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        if n >= len(sys.argv):
            fatal('{} requires an argument'.format(arg))
        requested_actions.output_config[config_output]['relation'] = \
            ('above', sys.argv[n])
        n += 1
    elif arg == '--below':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        if n >= len(sys.argv):
            fatal('{} requires an argument'.format(arg))
        requested_actions.output_config[config_output]['relation'] = \
            ('below', sys.argv[n])
        n += 1
    elif arg == '--same-as':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        if n >= len(sys.argv):
            fatal('{} requires an argument'.format(arg))
        requested_actions.output_config[config_output]['relation'] = \
            ('same-as', sys.argv[n])
        n += 1
    elif arg == '--rotate':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        if n >= len(sys.argv):
            fatal('{} requires an argument'.format(arg))
        requested_actions.output_config[config_output]['trans'] = \
            rot_to_trans(sys.argv[n])
        n += 1
    elif arg == '--primary':
        if not config_output:
            fatal('{} must be used after --output'.format(arg))
        requested_actions.primary = config_output
    else:
        fatal('unrecognized option: {}'.format(arg))

bus = dbus.SessionBus()
dc = bus.get_object('org.gnome.Mutter.DisplayConfig',
                    '/org/gnome/Mutter/DisplayConfig')

dc_iface = dbus.Interface(dc, dbus_interface='org.gnome.Mutter.DisplayConfig')
serial, monitors, logical_monitors, properties = dc_iface.GetCurrentState()

config_info = ConfigInfo(serial, monitors, logical_monitors, properties)
config_info.update_output_config(requested_actions)

if (len(requested_actions.output_config) == 0 or 
    requested_actions.print_current == True):
    config_info.print_properties()
    config_info.print_current_config()
    quit()

new_lm = monmap_to_lm(config_info, config_info.monmap)
print_new_config(new_lm)

if not requested_actions.dry_run and config_info.config_changed(new_lm):
    dc_iface.ApplyMonitorsConfig(config_info.serial,
                                 requested_actions.config_method, new_lm, {})
else:
    print('no changes made')