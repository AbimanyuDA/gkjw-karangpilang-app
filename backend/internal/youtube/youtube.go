// Package youtube mengambil metadata video YouTube TANPA API key Google:
//   - judul dari oEmbed (endpoint publik resmi YouTube)
//   - deskripsi & tanggal dari halaman video (data yang sama dengan yang dilihat browser)
//   - tanggal di judul ("Ibadah 27 April 2025") diutamakan bila ada
package youtube

import (
	"context"
	"encoding/json"
	"fmt"
	"html"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// Metadata adalah data video yang dipakai untuk mengisi form siaran.
type Metadata struct {
	VideoID     string     `json:"youtube_id"`
	Title       string     `json:"judul"`
	Description string     `json:"deskripsi"`
	Date        *time.Time `json:"tanggal"`
	Thumbnail   string     `json:"thumbnail"`
}

const maxPageBytes = 3 << 20

var (
	idPattern   = regexp.MustCompile(`(?:youtu\.be/|/v/|/u/\w/|embed/|live/|shorts/|watch\?v=|&v=)([A-Za-z0-9_-]{11})`)
	barePattern = regexp.MustCompile(`^[A-Za-z0-9_-]{11}$`)

	datePublished = regexp.MustCompile(`<meta itemprop="(?:datePublished|uploadDate)" content="([^"]+)"`)
	uploadDateRe  = regexp.MustCompile(`"(?:uploadDate|publishDate)":"([^"]+)"`)
	shortDescRe   = regexp.MustCompile(`"shortDescription":("(?:[^"\\]|\\.)*")`)
	metaDescRe    = regexp.MustCompile(`<meta name="description" content="([^"]*)"`)
	titleMetaRe   = regexp.MustCompile(`<meta name="title" content="([^"]*)"`)
)

// ExtractID mengambil ID video dari link YouTube (berbagai format) atau ID mentah.
func ExtractID(input string) (string, bool) {
	s := strings.TrimSpace(input)
	if barePattern.MatchString(s) {
		return s, true
	}
	if m := idPattern.FindStringSubmatch(s); m != nil {
		return m[1], true
	}
	return "", false
}

// Client mengambil metadata dari YouTube.
type Client struct {
	HTTP    *http.Client
	BaseURL string // default https://www.youtube.com (bisa diganti saat test)
}

// Fetch mengembalikan metadata; error hanya bila judul pun tidak bisa didapat.
func (c Client) Fetch(ctx context.Context, videoID string) (Metadata, error) {
	meta := Metadata{
		VideoID:   videoID,
		Thumbnail: "https://img.youtube.com/vi/" + videoID + "/hqdefault.jpg",
	}
	if title, err := c.oembedTitle(ctx, videoID); err == nil {
		meta.Title = title
	}

	// Halaman video: deskripsi & tanggal. Kegagalan di sini tidak fatal.
	if page, err := c.get(ctx, c.base()+"/watch?v="+url.QueryEscape(videoID)+"&hl=id"); err == nil {
		if meta.Title == "" {
			if m := titleMetaRe.FindStringSubmatch(page); m != nil {
				meta.Title = html.UnescapeString(m[1])
			}
		}
		meta.Description = parseDescription(page)
		meta.Date = parseUploadDate(page)
	}

	if meta.Title == "" {
		return Metadata{}, fmt.Errorf("video %s tidak ditemukan atau tidak publik", videoID)
	}
	if d := ParseDateFromTitle(meta.Title); d != nil {
		meta.Date = d // tanggal ibadah di judul lebih tepat daripada tanggal upload
	}
	return meta, nil
}

func (c Client) oembedTitle(ctx context.Context, videoID string) (string, error) {
	q := url.Values{"url": {"https://www.youtube.com/watch?v=" + videoID}, "format": {"json"}}
	body, err := c.get(ctx, c.base()+"/oembed?"+q.Encode())
	if err != nil {
		return "", err
	}
	var res struct {
		Title string `json:"title"`
	}
	if err := json.Unmarshal([]byte(body), &res); err != nil || res.Title == "" {
		return "", fmt.Errorf("oembed tanpa judul")
	}
	return res.Title, nil
}

func (c Client) get(ctx context.Context, rawURL string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, rawURL, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36")
	req.Header.Set("Accept-Language", "id,en;q=0.8")
	client := c.HTTP
	if client == nil {
		client = &http.Client{Timeout: 15 * time.Second}
	}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("status %d", resp.StatusCode)
	}
	b, err := io.ReadAll(io.LimitReader(resp.Body, maxPageBytes))
	return string(b), err
}

func (c Client) base() string {
	if c.BaseURL != "" {
		return strings.TrimRight(c.BaseURL, "/")
	}
	return "https://www.youtube.com"
}

func parseDescription(page string) string {
	if m := shortDescRe.FindStringSubmatch(page); m != nil {
		var s string
		if err := json.Unmarshal([]byte(m[1]), &s); err == nil {
			return s
		}
	}
	if m := metaDescRe.FindStringSubmatch(page); m != nil {
		return html.UnescapeString(m[1])
	}
	return ""
}

func parseUploadDate(page string) *time.Time {
	for _, re := range []*regexp.Regexp{datePublished, uploadDateRe} {
		m := re.FindStringSubmatch(page)
		if m == nil {
			continue
		}
		for _, layout := range []string{time.RFC3339, "2006-01-02T15:04:05-07:00", "2006-01-02"} {
			if t, err := time.Parse(layout, m[1]); err == nil {
				return &t
			}
		}
	}
	return nil
}

var months = map[string]time.Month{
	"januari": 1, "jan": 1, "februari": 2, "feb": 2, "maret": 3, "mar": 3,
	"april": 4, "apr": 4, "mei": 5, "juni": 6, "jun": 6, "juli": 7, "jul": 7,
	"agustus": 8, "agu": 8, "aug": 8, "september": 9, "sep": 9, "sept": 9,
	"oktober": 10, "okt": 10, "oct": 10, "november": 11, "nov": 11,
	"desember": 12, "des": 12, "dec": 12,
}

var (
	namedDateRe   = regexp.MustCompile(`(?i)\b(\d{1,2})\s+(januari|februari|maret|april|mei|juni|juli|agustus|september|oktober|november|desember|sept|jan|feb|mar|apr|jun|jul|agu|aug|sep|okt|oct|nov|des|dec)\.?\s+(\d{4})\b`)
	numericDateRe = regexp.MustCompile(`\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b`)
	wib           = time.FixedZone("WIB", 7*60*60)
)

// ParseDateFromTitle: "Ibadah Minggu 27 April 2025" / "Ibadah 27/04/2025" → tanggal (WIB).
func ParseDateFromTitle(title string) *time.Time {
	if m := namedDateRe.FindStringSubmatch(title); m != nil {
		if d := validDate(atoi(m[3]), months[strings.ToLower(m[2])], atoi(m[1])); d != nil {
			return d
		}
	}
	if m := numericDateRe.FindStringSubmatch(title); m != nil {
		return validDate(atoi(m[3]), time.Month(atoi(m[2])), atoi(m[1]))
	}
	return nil
}

func validDate(year int, month time.Month, day int) *time.Time {
	if month < 1 || month > 12 || day < 1 || day > 31 {
		return nil
	}
	d := time.Date(year, month, day, 0, 0, 0, 0, wib)
	if d.Month() != month { // tolak 31 Februari dll.
		return nil
	}
	return &d
}

func atoi(s string) int {
	n, _ := strconv.Atoi(s)
	return n
}
