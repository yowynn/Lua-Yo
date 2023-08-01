local tabler = require("tabler")

print("test1:")
print("########################################################")
local data = {
    { name = "Wynn", age = 18, },
    { name = "爱新觉罗·闪电", age = 19, },
}
local columns = {
    { key = "name", title = "名字", width = 20, },
    { key = "age", title = "年龄", width = 50, align = "right", handler = function(val)
        return val .. " years old"
    end, },
}
print(tabler.defines(columns).show(data))

print("test2:")
print("########################################################")
local data = {
    {"小明","男","18", "顺义区", "18223492341"},
    {"小红","女","20", "朝阳区", "18223492342"},
    {"小刚","男","22", "海淀区", "18223492343"},
    {"小霞","女","19", "丰台区", "18223492344"},
    {"小王","男","21", "石景山区", "18223492345"},
}
local columns = {
    {
        key = 0,
        title = "个人简介",
        width = nil,
        align = "left",
        handler = function(val, item)
            local sex = item[2] == "男" and "他" or "她"
            return string.format("%s是个%s孩子，今年%s岁了，家住北京%s，可以打电话号码%s找到%s~", item[1], item[2], item[3], item[4], item[5], sex)
        end,
    },
    {
        key = 0,
        title = "|",
        handler = function(val, item)
            return "|"
        end,
    },
}
print(tabler.defines(columns).show(data))

print("test3:")
print("########################################################")
local testdata = {
    [1] = {
        ["author_name"] = "刘芳",
        ["file_name"] = "test3.mp4",
        ["file_name_en"] = "test3.mp4",
        ["last_change_time"] = 1662457876000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/95/1/test3.mp4",
        ["task_id"] = "95",
    },
    [2] = {
        ["author_name"] = "部成",
        ["file_name"] = "a (1).png",
        ["file_name_en"] = "a (1).png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/28320/10/a (1).png",
        ["task_id"] = "28320",
    },
    [3] = {
        ["author_name"] = "前实",
        ["file_name"] = "a.png",
        ["file_name_en"] = "a.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/71076/6/a.png",
        ["task_id"] = "71076",
    },
    [4] = {
        ["author_name"] = "功功",
        ["file_name"] = "cankao02.png",
        ["file_name_en"] = "cankao02.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/62704/10/cankao02.png",
        ["task_id"] = "62704",
    },
    [5] = {
        ["author_name"] = "量动",
        ["file_name"] = "cankao03.png",
        ["file_name_en"] = "cankao03.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/68659/19/cankao03.png",
        ["task_id"] = "68659",
    },
    [6] = {
        ["author_name"] = "成量",
        ["file_name"] = "cankao04.png",
        ["file_name_en"] = "cankao04.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/50864/11/cankao04.png",
        ["task_id"] = "50864",
    },
    [7] = {
        ["author_name"] = "已全",
        ["file_name"] = "gbxk1.png",
        ["file_name_en"] = "gbxk1.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/53732/11/gbxk1.png",
        ["task_id"] = "53732",
    },
    [8] = {
        ["author_name"] = "发功",
        ["file_name"] = "gmxk3.png",
        ["file_name_en"] = "gmxk3.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/77095/18/gmxk3.png",
        ["task_id"] = "77095",
    },
    [9] = {
        ["author_name"] = "量前",
        ["file_name"] = "gmxk4.png",
        ["file_name_en"] = "gmxk4.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/65912/12/gmxk4.png",
        ["task_id"] = "65912",
    },
    [10] = {
        ["author_name"] = "实署",
        ["file_name"] = "gmxk5.png",
        ["file_name_en"] = "gmxk5.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/35623/12/gmxk5.png",
        ["task_id"] = "35623",
    },
    [11] = {
        ["author_name"] = "发功",
        ["file_name"] = "guxk2.png",
        ["file_name_en"] = "guxk2.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/16651/10/guxk2.png",
        ["task_id"] = "16651",
    },
    [12] = {
        ["author_name"] = "启署",
        ["file_name"] = "leijishengbei1.jpg",
        ["file_name_en"] = "leijishengbei1.jpg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/53908/11/leijishengbei1.jpg",
        ["task_id"] = "53908",
    },
    [13] = {
        ["author_name"] = "已功",
        ["file_name"] = "ljsb.jpg",
        ["file_name_en"] = "ljsb.jpg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/84353/3/ljsb.jpg",
        ["task_id"] = "84353",
    },
    [14] = {
        ["author_name"] = "成发",
        ["file_name"] = "sdsc.png",
        ["file_name_en"] = "sdsc.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/51896/11/sdsc.png",
        ["task_id"] = "51896",
    },
    [15] = {
        ["author_name"] = "布部",
        ["file_name"] = "shy24.jpg",
        ["file_name_en"] = "shy24.jpg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/64170/24/shy24.jpg",
        ["task_id"] = "64170",
    },
    [16] = {
        ["author_name"] = "功功",
        ["file_name"] = "syt.jpg",
        ["file_name_en"] = "syt.jpg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/9356/4/syt.jpg",
        ["task_id"] = "9356",
    },
    [17] = {
        ["author_name"] = "例量",
        ["file_name"] = "syt33.jpg",
        ["file_name_en"] = "syt33.jpg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/54202/23/syt33.jpg",
        ["task_id"] = "54202",
    },
    [18] = {
        ["author_name"] = "启部",
        ["file_name"] = "WOA20220830-154200.jpeg",
        ["file_name_en"] = "WOA20220830-154200.jpeg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/10719/11/WOA20220830-154200.jpeg",
        ["task_id"] = "10719",
    },
    [19] = {
        ["author_name"] = "功当",
        ["file_name"] = "WOA20220830-154216.jpeg",
        ["file_name_en"] = "WOA20220830-154216.jpeg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/50762/19/WOA20220830-154216.jpeg",
        ["task_id"] = "50762",
    },
    [20] = {
        ["author_name"] = "全布",
        ["file_name"] = "WOA20220830-154221.jpeg",
        ["file_name_en"] = "WOA20220830-154221.jpeg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/2192/18/WOA20220830-154221.jpeg",
        ["task_id"] = "2192",
    },
    [21] = {
        ["author_name"] = "功成",
        ["file_name"] = "WOA20220830-154225.jpeg",
        ["file_name_en"] = "WOA20220830-154225.jpeg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/20500/23/WOA20220830-154225.jpeg",
        ["task_id"] = "20500",
    },
    [22] = {
        ["author_name"] = "已量",
        ["file_name"] = "WOA20220830-154228.jpeg",
        ["file_name_en"] = "WOA20220830-154228.jpeg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/9055/2/WOA20220830-154228.jpeg",
        ["task_id"] = "9055",
    },
    [23] = {
        ["author_name"] = "数成",
        ["file_name"] = "WOA20220830-154232.jpeg",
        ["file_name_en"] = "WOA20220830-154232.jpeg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/40738/5/WOA20220830-154232.jpeg",
        ["task_id"] = "40738",
    },
    [24] = {
        ["author_name"] = "已启",
        ["file_name"] = "WOA20220830-154236.jpeg",
        ["file_name_en"] = "WOA20220830-154236.jpeg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/44694/5/WOA20220830-154236.jpeg",
        ["task_id"] = "44694",
    },
    [25] = {
        ["author_name"] = "署例",
        ["file_name"] = "WOA20220830-154241.png",
        ["file_name_en"] = "WOA20220830-154241.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/52827/3/WOA20220830-154241.png",
        ["task_id"] = "52827",
    },
    [26] = {
        ["author_name"] = "成量",
        ["file_name"] = "WOA20220830-154247.jpeg",
        ["file_name_en"] = "WOA20220830-154247.jpeg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/47236/7/WOA20220830-154247.jpeg",
        ["task_id"] = "47236",
    },
    [27] = {
        ["author_name"] = "署例",
        ["file_name"] = "WOA20220830-154251.jpeg",
        ["file_name_en"] = "WOA20220830-154251.jpeg",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/73436/12/WOA20220830-154251.jpeg",
        ["task_id"] = "73436",
    },
    [28] = {
        ["author_name"] = "例实",
        ["file_name"] = "xgt.png",
        ["file_name_en"] = "xgt.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/56908/13/xgt.png",
        ["task_id"] = "56908",
    },
    [29] = {
        ["author_name"] = "全全",
        ["file_name"] = "xgt2.png",
        ["file_name_en"] = "xgt2.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/68422/7/xgt2.png",
        ["task_id"] = "68422",
    },
    [30] = {
        ["author_name"] = "数功",
        ["file_name"] = "xgt34.png",
        ["file_name_en"] = "xgt34.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/28601/11/xgt34.png",
        ["task_id"] = "28601",
    },
    [31] = {
        ["author_name"] = "实署",
        ["file_name"] = "yjsd.png",
        ["file_name_en"] = "yjsd.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/22794/22/yjsd.png",
        ["task_id"] = "22794",
    },
    [32] = {
        ["author_name"] = "功功",
        ["file_name"] = "yjsd2.png",
        ["file_name_en"] = "yjsd2.png",
        ["last_change_time"] = 1661849465000,
        ["svn_url"] = "https://10.3.254.33/repos/course_resource/dev/24/7991/1/yjsd2.png",
        ["task_id"] = "7991",
    },
}


local testcolumn = {
    {
        key = "task_id",
        title = "ID",
        align = "right",
    }, {
        key = "last_change_time",
        title = "更新时间",
        align = "left",
        handler = function(data)
            return os.date("%Y/%m/%d %H:%M:%S", math.floor(data / 1000))
        end,
    }, {
        key = "file_name",
        title = "显示名",
        align = "left",
    }, {
        key = "file_name_en",
        title = "文件名",
        align = "left",
    }, {
        key = "author_name",
        title = "作者",
        align = "left",
    }, {
        key = "svn_url",
        title = "资源链接",
        align = "left",
    },
}

print(tabler.defines(testcolumn).show(testdata))
